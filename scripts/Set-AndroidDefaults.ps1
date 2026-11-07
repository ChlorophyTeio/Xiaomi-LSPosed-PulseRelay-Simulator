. "$PSScriptRoot/Common.ps1"
# Country/region is encoded in the system locale; Shanghai is the time zone.
$locale = (Invoke-Adb shell getprop persist.sys.locale).Trim()
Invoke-Adb shell settings put global auto_time_zone 0
Invoke-Adb shell settings put system system_locales zh-CN
if ($locale -ne 'zh-CN') {
    Invoke-Adb shell su -c 'setprop persist.sys.locale zh-CN'
    $saved = (Invoke-Adb shell getprop persist.sys.locale).Trim()
    if ($saved -ne 'zh-CN') { throw 'Could not persist the Simplified Chinese locale.' }
    # Android 12 applies the system-wide locale when its framework starts.
    Write-Host 'Applying Simplified Chinese / China defaults; restarting Android once...'
    Invoke-Adb reboot
    Start-Sleep -Seconds 3
    Wait-Android
}
$locale = (Invoke-Adb shell getprop persist.sys.locale).Trim()
$zone = (Invoke-Adb shell getprop persist.sys.timezone).Trim()
if ($locale -ne 'zh-CN' -or $zone -ne 'Asia/Shanghai') { throw "Android regional defaults did not apply: locale=$locale timezone=$zone" }
Write-Host 'Android region: Simplified Chinese / China; timezone: Asia/Shanghai'
