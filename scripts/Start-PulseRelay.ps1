param([switch]$WithoutBluetooth, [switch]$Headless)
. "$PSScriptRoot/Common.ps1"
New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot 'logs') | Out-Null
& "$PSScriptRoot/Initialize-Avd.ps1"
$devices = & $Adb devices
if ($devices -match "$Serial\s+device") { throw "$Serial is already running. Stop it first." }
if (!$WithoutBluetooth) {
    if ($Config.controller -notmatch '^usb:[0-9a-fA-F]{4}:[0-9a-fA-F]{4}$') { throw 'Run Configure-Bluetooth.cmd first to select this computer''s Bluetooth adapter.' }
    $bridgeArgs = @('-u', ('"' + (Join-Path $PSScriptRoot 'bluetooth_bridge.py') + '"'), '--controller', $Config.controller, '--port', $Config.bridgePort)
    $bridgeProcess = Start-Process -FilePath $BridgePython -ArgumentList $bridgeArgs -WorkingDirectory $ProjectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $ProjectRoot 'logs/bridge.stdout.log') -RedirectStandardError (Join-Path $ProjectRoot 'logs/bridge.stderr.log')
    $bridgeProcess.Id | Set-Content (Join-Path $ProjectRoot 'runtime/bridge.pid')
    $ready = $false
    # Allow the bounded firmware/reset steps to finish before the launcher expires.
    $bridgeDeadline = (Get-Date).AddSeconds(120)
    while ((Get-Date) -lt $bridgeDeadline) {
        $bridgeProcess.Refresh()
        if ($bridgeProcess.HasExited) {
            Get-Content (Join-Path $ProjectRoot 'logs/bridge.stderr.log') -Tail 30 -ErrorAction SilentlyContinue | Write-Host
            throw "Bluetooth bridge failed (exit $($bridgeProcess.ExitCode)). See logs/bridge.stderr.log."
        }
        if ((Get-Content (Join-Path $ProjectRoot 'logs/bridge.stdout.log') -Raw -ErrorAction SilentlyContinue) -match 'BRIDGE_READY') { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (!$ready) {
        Stop-Process -Id $bridgeProcess.Id -ErrorAction SilentlyContinue
        Get-Content (Join-Path $ProjectRoot 'logs/bridge.stderr.log') -Tail 30 -ErrorAction SilentlyContinue | Write-Host
        throw 'Bluetooth bridge startup timed out after 120 seconds. See logs/bridge.stderr.log for the last startup stage.'
    }
}
$emulatorArgs = @('-avd', $Config.avdName, '-port', $Config.adbPort, '-sysdir', ('"' + $ImageDir + '"'), '-no-snapshot', '-no-boot-anim', '-gpu', 'software', '-http-proxy', $Config.httpProxy)
if (!$WithoutBluetooth) { $emulatorArgs += @('-packet-streamer-endpoint', "127.0.0.1:$($Config.bridgePort)") }
if ($Headless) { $emulatorArgs += '-no-window' }
try {
    $windowStyle = if ($Headless) { 'Hidden' } else { 'Normal' }
    $emulatorProcess = Start-Process -FilePath $Emulator -ArgumentList $emulatorArgs -WorkingDirectory $ProjectRoot -WindowStyle $windowStyle -PassThru -RedirectStandardOutput (Join-Path $ProjectRoot 'logs/emulator.stdout.log') -RedirectStandardError (Join-Path $ProjectRoot 'logs/emulator.stderr.log')
    Wait-Android
    Invoke-Adb shell settings put global http_proxy '10.0.2.2:7897'
    Invoke-Adb shell settings put system screen_off_timeout 1800000
    Write-Output "Android ready: $Serial"
} catch {
    if ($bridgeProcess -and !$bridgeProcess.HasExited) { Stop-Process -Id $bridgeProcess.Id }
    throw
}
