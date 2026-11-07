#Requires -RunAsAdministrator
. "$PSScriptRoot/Common.ps1"
if ($Config.controller -notmatch '^usb:([0-9a-fA-F]{4}):([0-9a-fA-F]{4})$') { throw 'Configure a Bluetooth adapter first.' }
$hardwareId = "VID_$($Matches[1])&PID_$($Matches[2])"
$deviceId = $Config.bluetoothInstanceId
if (!$deviceId) {
    $found = @(Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like "USB\$hardwareId\*" })
    if ($found.Count -ne 1) { throw 'Run Configure-Bluetooth.cmd to select the exact device.' }
    $deviceId = $found[0].InstanceId
}
$service = (Get-PnpDeviceProperty -InstanceId $deviceId -KeyName DEVPKEY_Device_Service).Data
if ($service -eq 'BTHUSB') { Write-Output 'Intel Windows Bluetooth driver is already active.'; return }
if ($service -ne 'WinUSB') { throw "Unexpected driver service: $service. No changes made." }
$infName = (Get-PnpDeviceProperty -InstanceId $deviceId -KeyName DEVPKEY_Device_DriverInfPath).Data
if ($infName -notmatch '^oem\d+\.inf$') { throw 'Unexpected driver INF name.' }
$inf = Get-Content -LiteralPath (Join-Path $env:WINDIR "INF/$infName") -Raw
if ($inf -notmatch [regex]::Escape($hardwareId)) { throw 'INF does not match the selected adapter. No changes made.' }
& "$PSScriptRoot/Stop-PulseRelay.ps1"
$backups = @(Get-ChildItem (Join-Path $ProjectRoot 'runtime/bluetooth-original') -Filter '*.inf' -Recurse -ErrorAction SilentlyContinue)
if ($backups.Count -eq 1) { $backup = $backups[0].FullName }
else { $backup = Join-Path $ProjectRoot 'runtime/bluetooth-driver-backup/ibtusb.inf' }
if (!(Test-Path -LiteralPath $backup)) { throw 'Original Intel driver backup is missing.' }
& pnputil.exe /add-driver $backup
if ($LASTEXITCODE -ne 0) { throw 'Could not stage original Intel driver.' }
& pnputil.exe /delete-driver $infName /uninstall
if ($LASTEXITCODE -ne 0) { throw 'Could not remove the AX211 WinUSB driver. Use Device Manager to select the Intel Bluetooth driver.' }
& pnputil.exe /scan-devices
Write-Output 'Windows Bluetooth restore requested. Check Device Manager; restart Windows if indicated.'
