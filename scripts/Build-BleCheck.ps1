. "$PSScriptRoot/Common.ps1"
$build = Join-Path $ProjectRoot 'runtime/blecheck-build'
New-Item -ItemType Directory -Force -Path "$build/classes", "$build/dex" | Out-Null
$tools = Join-Path $Config.sdk 'build-tools/36.0.0'
$jar = Join-Path $Config.sdk 'platforms/android-34/android.jar'
if (!$env:JAVA_HOME) { throw 'Set JAVA_HOME to JDK 17 or newer before building.' }
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
& "$env:JAVA_HOME/bin/javac.exe" -source 8 -target 8 -classpath $jar -d "$build/classes" "$ProjectRoot/diagnostics/MainActivity.java"
if ($LASTEXITCODE) { throw 'javac failed' }
$classes = @(Get-ChildItem "$build/classes" -Filter '*.class' -Recurse | ForEach-Object FullName)
& "$tools/d8.bat" --lib $jar --min-api 31 --output "$build/dex" @classes
if ($LASTEXITCODE) { throw 'd8 failed' }
& "$tools/aapt.exe" package -f -M "$ProjectRoot/diagnostics/AndroidManifest.xml" -I $jar -F "$build/check.apk"
Push-Location "$build/dex"
try { & "$tools/aapt.exe" add "$build/check.apk" classes.dex } finally { Pop-Location }
if (!(Test-Path "$build/debug.keystore")) { & "$env:JAVA_HOME/bin/keytool.exe" -genkeypair -keystore "$build/debug.keystore" -storepass android -keypass android -alias androiddebugkey -dname 'CN=PulseRelay Local Debug' -keyalg RSA -validity 3650 | Out-Null }
& "$tools/apksigner.bat" sign --ks "$build/debug.keystore" --ks-pass pass:android --key-pass pass:android --out "$ProjectRoot/apks/BleCheck.apk" "$build/check.apk"
if ($LASTEXITCODE) { throw 'Signing failed' }
