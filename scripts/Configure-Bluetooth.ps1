#Requires -RunAsAdministrator
. "$PSScriptRoot/Common.ps1"
$candidates = @(Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}\\' -and $_.FriendlyName -match 'Bluetooth|蓝牙' })
if (!$candidates.Count) { throw 'No Bluetooth adapter found. Plug in an adapter and retry.' }
for ($i=0; $i -lt $candidates.Count; $i++) { Write-Output "[$($i+1)] $($candidates[$i].FriendlyName) $($candidates[$i].InstanceId)" }
$selection = [int](Read-Host 'Choose the adapter to dedicate to Android (number)')
if ($selection -lt 1 -or $selection -gt $candidates.Count) { throw 'Invalid choice.' }
$selected = $candidates[$selection-1]
$matched = [regex]::Match($selected.InstanceId, 'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})')
$cfgPath = Join-Path $ProjectRoot 'config.json'
$saved = Get-Content $cfgPath -Raw | ConvertFrom-Json
$saved.controller = "usb:$($matched.Groups[1].Value):$($matched.Groups[2].Value)"
$saved | Add-Member -NotePropertyName bluetoothInstanceId -NotePropertyValue $selected.InstanceId -Force
$saved | ConvertTo-Json | Set-Content $cfgPath -Encoding ascii
$backup = Join-Path $ProjectRoot 'runtime/bluetooth-original'
New-Item -ItemType Directory -Force $backup | Out-Null
$properties = Get-PnpDeviceProperty -InstanceId $selected.InstanceId -KeyName DEVPKEY_Device_DriverInfPath,DEVPKEY_Device_Service
$properties | Select-Object KeyName,Data | ConvertTo-Json | Set-Content (Join-Path $backup 'original.json')
$infName = ($properties | Where-Object KeyName -eq 'DEVPKEY_Device_DriverInfPath').Data
if ($infName -match '^oem\d+\.inf$') { & pnputil.exe /export-driver $infName $backup }
Write-Output "In Zadig choose Options > List All Devices, select $($selected.FriendlyName), VERIFY USB ID $($matched.Groups[1].Value):$($matched.Groups[2].Value), then replace its driver with WinUSB. Windows will lose use of this Bluetooth adapter. Restart Windows if requested."
Start-Process -FilePath (Join-Path $ProjectRoot 'downloads/zadig-2.9.exe') -WorkingDirectory $ProjectRoot
