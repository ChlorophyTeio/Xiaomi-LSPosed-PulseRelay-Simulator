. "$PSScriptRoot/Common.ps1"
$emulatorProcesses = @(Get-CimInstance Win32_Process | Where-Object {
    $_.Name -like 'qemu-system-*.exe' -and $_.CommandLine -and
    $_.CommandLine.Contains($ProjectRoot) -and
    $_.CommandLine -match (('-port\s+' + [regex]::Escape([string]$Config.adbPort)) + '(\s|$)')
})
if ((& $Adb devices) -match "$Serial\s") { & $Adb -s $Serial emu kill }
for ($i = 0; $i -lt 90; $i++) {
    if ((& $Adb devices) -notmatch "$Serial\s") { break }
    Start-Sleep -Milliseconds 500
}
# ADB disconnects before QEMU finishes shutting down. Keep the bridge alive
# until QEMU exits so its transport is not removed during emulator cleanup.
foreach ($emulatorProcess in $emulatorProcesses) {
    $running = Get-Process -Id $emulatorProcess.ProcessId -ErrorAction SilentlyContinue
    if ($running -and !$running.WaitForExit(45000)) {
        throw 'Emulator is still shutting down. Bluetooth bridge kept running; retry after closing the emulator.'
    }
}
$pidFile = Join-Path $ProjectRoot 'runtime/bridge.pid'
if (Test-Path -LiteralPath $pidFile) {
    $bridgePid = [int](Get-Content -LiteralPath $pidFile)
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$bridgePid" -ErrorAction SilentlyContinue
    if ($p -and $p.CommandLine -like '*bluetooth_bridge.py*') { Stop-Process -Id $bridgePid }
    Remove-Item -LiteralPath $pidFile
}
