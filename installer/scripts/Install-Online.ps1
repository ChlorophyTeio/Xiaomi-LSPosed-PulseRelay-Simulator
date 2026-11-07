param(
    [string]$InstallDirectory = '',
    [string]$SettingsPath = '',
    [string]$ManifestPath = '',
    [switch]$DownloadOnly
)
$ErrorActionPreference = 'Stop'
$PackageRoot = Split-Path $PSScriptRoot -Parent
. "$PSScriptRoot/Installer-Core.ps1"
try {
    if (!$SettingsPath) { $SettingsPath = Join-Path $PackageRoot 'download-settings.json' }
    if (!(Test-Path -LiteralPath $SettingsPath)) {
        Copy-Item -LiteralPath (Join-Path $PackageRoot 'download-settings.example.json') -Destination $SettingsPath
    }
    if (!$ManifestPath) { $ManifestPath = Join-Path $PackageRoot 'payload-manifest.json' }
    $settings = Get-Content -LiteralPath $SettingsPath -Raw | ConvertFrom-Json
    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if ($manifest.archiveRoot -ne 'PulseRelay-Windows-Clean' -or $manifest.archiveSha256 -notmatch '^[0-9a-f]{64}$' -or [long]$manifest.archiveSize -le 0) { throw 'Invalid runtime archive manifest.' }
    $totalSize = 0L
    $names = @{}
    foreach ($part in $manifest.parts) {
        if ($names.ContainsKey([string]$part.name)) { throw 'Duplicate runtime download part.' }
        $names[[string]$part.name] = $true
        $totalSize += [long]$part.size
    }
    if (!$names.Count -or $totalSize -ne [long]$manifest.archiveSize) { throw 'Runtime part sizes do not match the manifest archive size.' }
    if (!$InstallDirectory) { $InstallDirectory = Join-Path $PackageRoot 'PulseRelay' }
    $target = [IO.Path]::GetFullPath($InstallDirectory)
    $cache = Join-Path $PackageRoot 'cache'
    $curl = Join-Path $env:WINDIR 'System32/curl.exe'
    if (!(Test-Path -LiteralPath $curl)) { throw 'Windows curl.exe is missing. This installer requires Windows 11 x64.' }
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { throw 'Windows ARM is not supported by this x64 runtime.' }
    if ($settings.downloadProxyMode -notin @('direct','environment','custom')) { throw 'downloadProxyMode must be direct, environment, or custom.' }
    if ($settings.downloadProxyMode -eq 'custom' -and $settings.downloadProxyUrl -notmatch '^(https?|socks5h?)://') { throw 'Use an http://, https://, socks5://, or socks5h:// proxy URL.' }
    $marker = Join-Path $target 'online-install.json'
    if (Test-Path -LiteralPath $marker) {
        $previous = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
        if ($previous.payloadSha256 -eq $manifest.archiveSha256) {
            Assert-RuntimeFiles $target
            Write-Host "Already installed: $target"
            exit 0
        }
        throw 'A different runtime is already installed. Choose a new InstallDirectory to preserve its user data.'
    }
    if (Test-Path -LiteralPath $target) { throw 'InstallDirectory already exists. Choose a new directory; existing files will not be overwritten.' }
    $drive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($target))
    if ($drive.AvailableFreeSpace -lt 28GB) { throw 'At least 28 GiB of free disk space is required for download, extraction, and runtime.' }
    New-Item -ItemType Directory -Force -Path $cache | Out-Null
    Write-Host "Runtime: $($manifest.runtimeVersion); download: $([math]::Round($manifest.archiveSize / 1GB, 2)) GiB"
    Write-Host "Download proxy mode: $($settings.downloadProxyMode)"
    foreach ($part in $manifest.parts) { Get-PayloadPart $part $cache $settings $curl }
    $archive = Join-Path $cache 'PulseRelay-Windows-Clean.zip'
    if (!(Test-PayloadFile $archive $manifest.archiveSize $manifest.archiveSha256)) {
        Write-Host 'Combining verified download parts...'
        $combined = $archive + '.combining'
        $output = [IO.File]::Create($combined)
        try {
            foreach ($part in $manifest.parts) {
                $inputStream = [IO.File]::OpenRead((Join-Path $cache $part.name))
                try { $inputStream.CopyTo($output) } finally { $inputStream.Dispose() }
            }
        } finally { $output.Dispose() }
        if (!(Test-PayloadFile $combined $manifest.archiveSize $manifest.archiveSha256)) { throw 'Combined archive checksum failed. Cached files have been retained.' }
        if (Test-Path -LiteralPath $archive) { Move-Item -LiteralPath $archive -Destination ($archive + '.invalid-' + [guid]::NewGuid().ToString('N')) }
        Move-Item -LiteralPath $combined -Destination $archive
    }
    if ($DownloadOnly) { Write-Host "Download and SHA256 verification complete: $archive"; exit 0 }
    Write-Host 'Extracting runtime; this can take several minutes...'
    $staging = $target + '.installing-' + [guid]::NewGuid().ToString('N')
    Expand-PayloadArchive $archive $staging $manifest.archiveRoot
    Assert-RuntimeFiles $staging
    $record = @{ installerVersion = '0.2.0'; runtimeVersion = $manifest.runtimeVersion; payloadSha256 = $manifest.archiveSha256 }
    $record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $staging 'online-install.json') -Encoding ascii
    if (Test-Path -LiteralPath $target) { throw "InstallDirectory appeared during installation. Extracted files retained at $staging" }
    Move-Item -LiteralPath $staging -Destination $target
    Write-Host "Installed: $target"
    Write-Host 'Next: First-Run-Drivers.cmd, Configure-Bluetooth.cmd, then Start-PulseRelay.cmd in the installed directory.'
    Write-Host 'Download proxy settings are separate from the Android app proxy in config.json.'
} catch {
    Write-Host "Installation failed: $_"
    Write-Host 'Downloads are retained in cache. Check download-settings.json and rerun Install.cmd to resume.'
    exit 1
}
