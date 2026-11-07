. "$PSScriptRoot/Common.ps1"
& $Adb -s $Serial emu kill
for ($i = 0; $i -lt 90; $i++) {
    if ((& $Adb devices) -notmatch "$Serial\s") { break }
    Start-Sleep -Milliseconds 500
}
$pidFile = Join-Path $ProjectRoot 'runtime/bridge.pid'
if (Test-Path -LiteralPath $pidFile) {
    $bridgePid = [int](Get-Content -LiteralPath $pidFile)
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$bridgePid" -ErrorAction SilentlyContinue
    if ($p -and $p.CommandLine -like '*bluetooth_bridge.py*') { Stop-Process -Id $bridgePid }
    Remove-Item -LiteralPath $pidFile
}
