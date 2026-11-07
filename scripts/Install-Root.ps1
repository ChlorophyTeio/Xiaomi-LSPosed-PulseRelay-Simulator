. "$PSScriptRoot/Common.ps1"
Wait-Android
$rootTool = Join-Path $ProjectRoot 'runtime/rootAVD'
New-Item -ItemType Directory -Force -Path $rootTool | Out-Null
Copy-Item -LiteralPath (Join-Path $ProjectRoot 'downloads/rootAVD.bat') -Destination $rootTool -Force
$source = Get-Content -LiteralPath (Join-Path $ProjectRoot 'downloads/rootAVD.sh') -Raw
# Pin the bundled Magisk instead of consulting/upgrading to a moving online version.
$source = $source.Replace('CheckAVDIsOnline() {', "CheckAVDIsOnline() {`n    AVDIsOnline=false; export AVDIsOnline; return")
[IO.File]::WriteAllText((Join-Path $rootTool 'rootAVD.sh'), $source.Replace("`r`n", "`n"), [Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath (Join-Path $ProjectRoot 'downloads/Magisk-v25.2.apk') -Destination (Join-Path $rootTool 'Magisk.zip') -Force
$relativeRamdisk = "system-images\android-$($Config.apiLevel)\$($Config.imageTag)\x86_64\ramdisk.img"
Push-Location $rootTool
try { & .\rootAVD.bat $relativeRamdisk } finally { Pop-Location }
Write-Output 'Ramdisk patch finished. Restart using Start-PulseRelay.cmd, then run Install-AndroidApps.ps1.'
