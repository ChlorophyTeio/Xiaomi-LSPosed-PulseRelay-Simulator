. "$PSScriptRoot/Common.ps1"
Wait-Android
Invoke-Adb root
Start-Sleep -Seconds 2
$identity = Invoke-Adb shell id
if ("$identity" -notmatch 'uid=0') { throw 'Magisk su is not working.' }
& $BridgePython (Join-Path $PSScriptRoot 'prepare_magisk_core.py')
if ($LASTEXITCODE) { throw 'Magisk core extraction failed.' }
Invoke-Adb push (Join-Path $ProjectRoot 'runtime/magisk-core/.') /data/adb/magisk/
Invoke-Adb shell chmod -R 755 /data/adb/magisk
Invoke-Adb install -r (Join-Path $ProjectRoot 'downloads/Magisk-v25.2.apk')
Invoke-Adb push (Join-Path $ProjectRoot 'downloads/LSPosed-v1.9.2-7024-zygisk-release.zip') /data/local/tmp/lsposed.zip
Invoke-Adb push (Join-Path $PSScriptRoot 'install-modules.sh') /data/local/tmp/install-modules.sh
Invoke-Adb shell sh /data/local/tmp/install-modules.sh
Invoke-Adb install -r (Join-Path $ProjectRoot 'apks/MiFitness-official.apk')
Invoke-Adb shell settings put global http_proxy '10.0.2.2:7897'
Invoke-Adb shell settings put system screen_off_timeout 1800000
Write-Output 'LSPosed and Mi Fitness installed. Stop/start Android to activate Zygisk and LSPosed.'
