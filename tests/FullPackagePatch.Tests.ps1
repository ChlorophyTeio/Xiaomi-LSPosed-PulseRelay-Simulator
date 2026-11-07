param([Parameter(Mandatory=$true)][string]$PatchDirectory)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$work=Join-Path $repo ('runtime/patch-test-'+[guid]::NewGuid().ToString('N'))
$target=Join-Path $work 'Existing Full Package'
New-Item -ItemType Directory -Force -Path "$target/scripts","$target/runtime/sdk/emulator","$target/runtime/android-home/avd" | Out-Null
'{"adbPort":5598,"controller":"usb:13D3:3617","customSetting":"preserve"}' | Set-Content "$target/config.json" -Encoding ascii
foreach($name in @('Common.ps1','Get-RealtekFirmware.ps1','realtek_8922.py','Start-PulseRelay.ps1')) { 'original script' | Set-Content "$target/scripts/$name" -Encoding ascii }
'EXE fixture' | Set-Content "$target/runtime/sdk/emulator/emulator.exe" -Encoding ascii
'Android user data sentinel' | Set-Content "$target/runtime/android-home/avd/userdata-fixture.img" -Encoding ascii
$protected=@("$target/config.json","$target/runtime/android-home/avd/userdata-fixture.img","$target/scripts/Common.ps1")
$before=@{};foreach($path in $protected){$before[$path]=(Get-FileHash -LiteralPath $path).Hash}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PatchDirectory 'Apply-FullPackage-Update.ps1') -InstallDirectory $target
if($LASTEXITCODE -ne 0){throw 'Patch application failed'}
foreach($path in $protected){if((Get-FileHash -LiteralPath $path).Hash -ne $before[$path]){throw "Protected file changed: $path"}}
$backup=@(Get-ChildItem "$target/updates/backups" -Directory)
if($backup.Count -ne 1 -or (Get-Content (Join-Path $backup[0].FullName 'Start-PulseRelay.ps1') -Raw).Trim() -ne 'original script'){throw 'Original launcher backup missing'}
foreach($name in @('Start-PulseRelay.ps1','Set-AndroidDefaults.ps1')){if((Get-FileHash "$target/scripts/$name").Hash -ne (Get-FileHash (Join-Path $PatchDirectory "payload/$name")).Hash){throw 'Installed script mismatch'}}
$bad=Join-Path $work 'bad-patch';Copy-Item -LiteralPath $PatchDirectory -Destination $bad -Recurse
'tampered' | Add-Content "$bad/payload/Start-PulseRelay.ps1"
$startHash=(Get-FileHash "$target/scripts/Start-PulseRelay.ps1").Hash
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$bad/Apply-FullPackage-Update.ps1" -InstallDirectory $target
if($LASTEXITCODE -eq 0 -or (Get-FileHash "$target/scripts/Start-PulseRelay.ps1").Hash -ne $startHash){throw 'Tampered patch was not rejected before changing files'}
Write-Host 'PASS: script update, original backup, configuration/user-data preservation, and tamper rejection.'
