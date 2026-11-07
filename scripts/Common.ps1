$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path $PSScriptRoot -Parent
if (!(Test-Path (Join-Path $ProjectRoot 'config.json'))) {
    Copy-Item (Join-Path $ProjectRoot 'config.example.json') (Join-Path $ProjectRoot 'config.json')
}
$Config = Get-Content -LiteralPath (Join-Path $ProjectRoot 'config.json') -Raw | ConvertFrom-Json
if (![IO.Path]::IsPathRooted($Config.sdk)) { $Config.sdk = Join-Path $ProjectRoot $Config.sdk }
$env:HTTP_PROXY = $Config.httpProxy
$env:HTTPS_PROXY = $Config.httpProxy
$env:ALL_PROXY = $Config.socksProxy
$env:NO_PROXY = 'localhost,127.0.0.1,::1,10.0.2.2'
$env:no_grpc_proxy = 'localhost,127.0.0.1,::1'
$env:ANDROID_HOME = Join-Path $ProjectRoot 'runtime/sdk'
$env:ANDROID_SDK_ROOT = $Config.sdk
$env:ANDROID_USER_HOME = Join-Path $ProjectRoot 'runtime/android-home'
$env:ANDROID_AVD_HOME = Join-Path $env:ANDROID_USER_HOME 'avd'
$Adb = Join-Path $env:ANDROID_HOME 'platform-tools/adb.exe'
$Emulator = Join-Path $Config.sdk 'emulator/emulator.exe'
$BridgePython = Join-Path $ProjectRoot 'runtime/python/python.exe'
if (!(Test-Path -LiteralPath $BridgePython)) { $BridgePython = Join-Path $ProjectRoot 'runtime/bridge-venv/Scripts/python.exe' }
$ImageDir = Join-Path $env:ANDROID_HOME ("system-images/android-$($Config.apiLevel)/$($Config.imageTag)/x86_64")
$Serial = 'emulator-' + $Config.adbPort
$env:ANDROID_SERIAL = $Serial
$env:PATH = "$(Split-Path $Adb);$env:PATH"
$env:BUMBLE_INTEL_FIRMWARE_DIR = Join-Path $ProjectRoot 'runtime/intel-firmware'
function Invoke-Adb {
    & $Adb -s $Serial @args
    if ($LASTEXITCODE -ne 0) { throw "adb failed ($LASTEXITCODE): $args" }
}
function Wait-Android([int]$TimeoutSeconds = 240) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        # Reconnect explicitly when a newly started ADB server has not discovered
        # an already running emulator (common after moving the portable folder).
        & $Adb connect ("127.0.0.1:" + ($Config.adbPort + 1)) 2>$null | Out-Null
        $boot = & $Adb -s $Serial shell getprop sys.boot_completed 2>$null
        if ($LASTEXITCODE -eq 0 -and "$boot".Trim() -eq '1') { return }
        Start-Sleep -Seconds 2
    }
    throw "Android did not boot within $TimeoutSeconds seconds. Check logs/emulator.*.log."
}
