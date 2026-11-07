. "$PSScriptRoot/Common.ps1"
if (!(Test-Path -LiteralPath (Join-Path $ImageDir 'system.img'))) { throw "Android $($Config.apiLevel) image missing." }
$avdDir = Join-Path $env:ANDROID_AVD_HOME ($Config.avdName + '.avd')
New-Item -ItemType Directory -Force -Path $avdDir | Out-Null
$configPath = Join-Path $avdDir 'config.ini'
@"
avd.ini.encoding=UTF-8
path=$avdDir
target=android-$($Config.apiLevel)
"@ | Set-Content -LiteralPath (Join-Path $env:ANDROID_AVD_HOME ($Config.avdName + '.ini')) -Encoding ascii
if (Test-Path -LiteralPath $configPath) {
    $existing = Get-Content -LiteralPath $configPath -Raw
    $existing = [regex]::Replace($existing, '(?m)^image\.sysdir\.1=.*$', [System.Text.RegularExpressions.MatchEvaluator]{ param($m) "image.sysdir.1=$ImageDir\" })
    Set-Content -LiteralPath $configPath -Value $existing -Encoding ascii
    Write-Output "AVD ready: $avdDir"
    return
}
@"
AvdId=$($Config.avdName)
avd.ini.displayname=PulseRelay Root + Bluetooth
avd.ini.encoding=UTF-8
abi.type=x86_64
hw.cpu.arch=x86_64
hw.cpu.ncore=4
hw.ramSize=3072
hw.gpu.enabled=yes
hw.gpu.mode=software
hw.lcd.width=1080
hw.lcd.height=1920
hw.lcd.density=420
hw.keyboard=yes
hw.battery=yes
hw.audioInput=no
hw.camera.back=none
hw.camera.front=none
hw.gps=yes
hw.sensors.orientation=yes
hw.sensors.proximity=yes
hw.mainKeys=no
hw.device.name=pixel_5
hw.device.manufacturer=Google
disk.dataPartition.size=8G
image.sysdir.1=$ImageDir\
tag.id=$($Config.imageTag)
tag.display=Google APIs
target=android-$($Config.apiLevel)
PlayStore.enabled=false
showDeviceFrame=no
fastboot.forceColdBoot=yes
fastboot.forceFastBoot=no
"@ | Set-Content -LiteralPath $configPath -Encoding ascii
Write-Output "Created AVD: $avdDir"
