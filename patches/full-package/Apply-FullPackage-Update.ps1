param([string]$InstallDirectory = '')
$ErrorActionPreference = 'Stop'
try {
    if (!$InstallDirectory) {
        foreach ($candidate in @($PSScriptRoot, (Split-Path $PSScriptRoot -Parent))) {
            if (Test-Path -LiteralPath (Join-Path $candidate 'config.json')) { $InstallDirectory = $candidate; break }
        }
    }
    if (!$InstallDirectory) { $InstallDirectory = (Read-Host 'Enter the existing PulseRelay installation folder').Trim().Trim('"') }
    $root = (Resolve-Path -LiteralPath $InstallDirectory).Path.TrimEnd('\')
    foreach ($name in @('config.json','scripts/Common.ps1','scripts/Get-RealtekFirmware.ps1','scripts/realtek_8922.py','runtime/sdk/emulator/emulator.exe')) {
        if (!(Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)) { throw 'This update requires the full v0.1.2 package or an online-installed runtime. Select its root folder.' }
    }
    $config = Get-Content -LiteralPath (Join-Path $root 'config.json') -Raw | ConvertFrom-Json
    $portPattern = '-port\s+' + [regex]::Escape([string]$config.adbPort) + '(\s|$)'
    $active = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -like 'qemu-system-*.exe' -and $_.CommandLine -and $_.CommandLine.IndexOf($root, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and $_.CommandLine -match $portPattern
    })
    if ($active.Count) { throw 'The emulator is running. Close it with Stop-PulseRelay.cmd, wait for it to exit, and rerun this update.' }
    $manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'patch-manifest.json') -Raw | ConvertFrom-Json
    $names = @('Set-AndroidDefaults.ps1','Start-PulseRelay.ps1')
    if (@($manifest.files).Count -ne $names.Count -or $manifest.version -ne '0.2.1') { throw 'Invalid patch manifest.' }
    foreach ($name in $names) {
        $entry = @($manifest.files | Where-Object name -eq $name)
        if ($entry.Count -ne 1 -or $entry[0].sha256 -notmatch '^[0-9a-f]{64}$') { throw 'Invalid patch file entry.' }
        $source = Join-Path $PSScriptRoot "payload/$name"
        if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $entry[0].sha256) { throw "Patch checksum failed: $name" }
    }
    $backup = Join-Path $root ('updates/backups/v0.2.1-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    foreach ($name in $names) {
        $destination = Join-Path $root "scripts/$name"
        if (Test-Path -LiteralPath $destination) { Copy-Item -LiteralPath $destination -Destination (Join-Path $backup $name) }
    }
    # Install the helper before its caller. Never touch config.json or guest disks.
    foreach ($name in $names) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot "payload/$name") -Destination (Join-Path $root "scripts/$name") -Force
    }
    Write-Host "Updated: $root"
    Write-Host "Original scripts backed up: $backup"
    Write-Host 'Next launch defaults: Simplified Chinese, China, Asia/Shanghai.'
    Write-Host 'Android may restart once to apply the language. Accounts and Android data were retained.'
} catch { Write-Host "Update failed: $_"; exit 1 }
