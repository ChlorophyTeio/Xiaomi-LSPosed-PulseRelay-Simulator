. "$PSScriptRoot/Common.ps1"
Write-Output '--- Android / Magisk ---'
Invoke-Adb shell 'getprop ro.build.version.release; getprop ro.product.cpu.abilist; su -c id; magisk -v'
Write-Output '--- LSPosed ---'
Invoke-Adb shell 'ps -A | grep lspd; cat /data/adb/modules/zygisk_lsposed/module.prop'
Write-Output '--- Domestic Mi Fitness ---'
Invoke-Adb shell 'dumpsys package com.mi.health | grep -E "versionName=|versionCode="'
Write-Output '--- Physical Bluetooth ---'
Invoke-Adb shell 'dumpsys bluetooth_manager | sed -n "1,15p"'
Write-Output '--- Bridge ---'
Get-Content (Join-Path $ProjectRoot 'logs/bridge.stdout.log') -Tail 5
