$ErrorActionPreference = 'Stop'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    try {
        $process = Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $PSCommandPath + '"')) -PassThru -Wait
        exit $process.ExitCode
    } catch { Write-Host "Administrator access is required: $_"; exit 1 }
}
try {
    . "$PSScriptRoot/Common.ps1"
    $deviceId = $Config.bluetoothInstanceId
    if (!$deviceId -and $Config.controller -match '^usb:([0-9a-f]{4}):([0-9a-f]{4})$') {
        $found = @(Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -like "USB\VID_$($Matches[1])&PID_$($Matches[2])\*" })
        if ($found.Count -ne 1) { throw 'Run Configure-Bluetooth.cmd to select the exact adapter.' }
        $deviceId = $found[0].InstanceId
    }
    if (!$deviceId -or $deviceId -notmatch '^USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}\\') { throw 'Invalid Bluetooth adapter in config.json.' }
    $device = Get-PnpDevice -InstanceId $deviceId -PresentOnly
    $service = (Get-PnpDeviceProperty -InstanceId $deviceId -KeyName DEVPKEY_Device_Service).Data
    $restoreInf = Join-Path $env:WINDIR 'INF/bth.inf'
    if ($deviceId -like 'USB\VID_13D3&PID_3617\*') {
        $restoreInf = Join-Path $ProjectRoot 'runtime/realtek-bluetooth/x64/rtkbtfilter.inf'
        & "$PSScriptRoot/Get-RealtekBluetoothDriver.ps1"
    } elseif ($service -eq 'BTHUSB') {
        Write-Host 'Windows Bluetooth driver is already active.'; exit 0
    } else {
        $hardwareId = ($deviceId -split '\\')[1]
        $backups = @(Get-ChildItem (Join-Path $ProjectRoot 'runtime/bluetooth-original') -Filter '*.inf' -Recurse -ErrorAction SilentlyContinue)
        $legacyBackup = Join-Path $ProjectRoot 'runtime/bluetooth-driver-backup/ibtusb.inf'
        if (Test-Path -LiteralPath $legacyBackup) { $backups += Get-Item -LiteralPath $legacyBackup }
        $matchingBackups = @($backups | Where-Object {
            $text = Get-Content -LiteralPath $_.FullName -Raw
            $text -match '(?im)^\s*Class\s*=\s*Bluetooth\s*$' -and $text -match [regex]::Escape($hardwareId)
        })
        if ($matchingBackups.Count -ne 1) { throw 'No unique original Bluetooth driver backup found. Install the motherboard vendor Bluetooth driver.' }
        $restoreInf = $matchingBackups[0].FullName
    }
    if ($service -notin @('WinUSB', 'BTHUSB')) { throw "Unexpected driver service: $service. No changes made." }
    $compatibleIds = (Get-PnpDeviceProperty -InstanceId $deviceId -KeyName DEVPKEY_Device_CompatibleIds).Data
    if ($compatibleIds -notcontains 'USB\Class_E0&SubClass_01&Prot_01') { throw 'Adapter does not advertise standard USB Bluetooth support. No changes made.' }
    $devices = & $Adb devices
    if ($devices -match "$Serial\s") { & "$PSScriptRoot/Stop-PulseRelay.ps1" }
    Get-CimInstance Win32_Process -Filter "Name='python.exe'" | Where-Object {
        $_.CommandLine -and $_.CommandLine.Contains((Join-Path $PSScriptRoot 'bluetooth_bridge.py'))
    } | ForEach-Object { Stop-Process -Id $_.ProcessId }
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class PulseRelayBluetoothRestore {
    [DllImport("newdev.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool UpdateDriverForPlugAndPlayDevices(
        IntPtr hwnd, string hardwareId, string infPath, uint flags, out bool rebootRequired);
}
"@
    $hardwareId = ($deviceId -split '\\')[1]
    $rebootRequired = $false
    Write-Host "Restoring Windows Bluetooth: $($device.FriendlyName) ($hardwareId)"
    $ok = [PulseRelayBluetoothRestore]::UpdateDriverForPlugAndPlayDevices([IntPtr]::Zero, "USB\$hardwareId", $restoreInf, 1, [ref]$rebootRequired)
    if (!$ok) {
        $errorCode = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
        throw "Driver installation failed (Win32 error $errorCode)."
    }
    if ($rebootRequired) { Write-Host 'Driver restored. Restart Windows to finish.' } else {
        $service = (Get-PnpDeviceProperty -InstanceId $deviceId -KeyName DEVPKEY_Device_Service).Data
        if ($service -ne 'BTHUSB') { throw "Driver verification returned $service. Check Device Manager." }
        Write-Host 'Windows Bluetooth restored. No restart required.'
    }
} catch { Write-Host "Bluetooth restore failed: $_"; exit 1 }
