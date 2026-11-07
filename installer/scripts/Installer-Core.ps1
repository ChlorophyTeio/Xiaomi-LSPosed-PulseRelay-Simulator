function Test-PayloadFile([string]$Path, [long]$Size, [string]$Sha256) {
    if (!(Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    if ((Get-Item -LiteralPath $Path).Length -ne $Size) { return $false }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -eq $Sha256
}
function Get-PayloadPart($Part, [string]$Cache, $Settings, [string]$Curl) {
    if ($Part.name -notmatch '^PulseRelay-Windows-Clean\.zip\.part[0-9]{3}$' -or $Part.sha256 -notmatch '^[0-9a-f]{64}$' -or [long]$Part.size -le 0) { throw 'Invalid download manifest entry.' }
    $uri = [uri]$Part.url
    if ($uri.Scheme -ne 'https') { throw 'Runtime downloads must use HTTPS.' }
    $destination = Join-Path $Cache $Part.name
    if (Test-PayloadFile $destination $Part.size $Part.sha256) { Write-Host "Verified cached $($Part.name)"; return }
    if (Test-Path -LiteralPath $destination) { Move-Item -LiteralPath $destination -Destination ($destination + '.invalid-' + [guid]::NewGuid().ToString('N')) }
    $partial = $destination + '.download'
    # A complete but invalid response cannot be resumed; retain it separately.
    if ((Test-Path -LiteralPath $partial) -and (Get-Item -LiteralPath $partial).Length -ge [long]$Part.size) {
        if (Test-PayloadFile $partial $Part.size $Part.sha256) { Move-Item -LiteralPath $partial -Destination $destination; return }
        Move-Item -LiteralPath $partial -Destination ($partial + '.invalid-' + [guid]::NewGuid().ToString('N'))
    }
    $curlArgs = @('--fail','--location','--retry','3','--retry-delay','2','--connect-timeout','20','--continue-at','-','--output',$partial,'--proto','=https','--proto-redir','=https')
    if ($Settings.downloadProxyMode -eq 'direct') { $curlArgs += @('--noproxy','*') }
    elseif ($Settings.downloadProxyMode -eq 'custom') { $curlArgs += @('--proxy',[string]$Settings.downloadProxyUrl,'--noproxy','localhost,127.0.0.1,::1') }
    $curlArgs += [string]$Part.url
    Write-Host "Downloading $($Part.name)..."
    $savedPreference = $ErrorActionPreference
    try {
        # Windows PowerShell 5.1 otherwise turns curl's progress stderr into errors.
        $ErrorActionPreference = 'Continue'
        & $Curl @curlArgs
        $curlExit = $LASTEXITCODE
    } finally { $ErrorActionPreference = $savedPreference }
    if ($curlExit -ne 0) { throw "Download failed (curl $curlExit): $($Part.name)" }
    if (!(Test-PayloadFile $partial $Part.size $Part.sha256)) { throw "Download SHA256 mismatch: $($Part.name). No runtime was installed." }
    Move-Item -LiteralPath $partial -Destination $destination
    Write-Host "Verified $($Part.name)"
}
function Expand-PayloadArchive([string]$Archive, [string]$Destination, [string]$ArchiveRoot) {
    Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
    if (Test-Path -LiteralPath $Destination) { throw 'Extraction staging directory already exists.' }
    $fullRoot = [IO.Path]::GetFullPath($Destination).TrimEnd('\') + '\'
    $prefix = $ArchiveRoot.TrimEnd('/') + '/'
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $files = @()
        foreach ($entry in $zip.Entries) {
            if (!$entry.FullName.StartsWith($prefix, [StringComparison]::Ordinal)) { throw 'Archive contains an unexpected root directory.' }
            $relative = $entry.FullName.Substring($prefix.Length).Replace('/','\')
            if (!$relative) { continue }
            if ($relative.Contains(':') -or $relative.StartsWith('\')) { throw 'Unsafe archive entry path.' }
            $path = [IO.Path]::GetFullPath((Join-Path $Destination $relative))
            if (!$path.StartsWith($fullRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Archive path escapes the installation directory.' }
            $files += [pscustomobject]@{ Entry = $entry; Path = $path }
        }
        New-Item -ItemType Directory -Path $Destination | Out-Null
        foreach ($file in $files) {
            if ($file.Entry.FullName.EndsWith('/')) { [IO.Directory]::CreateDirectory($file.Path) | Out-Null; continue }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($file.Path)) | Out-Null
            $inputStream = $file.Entry.Open()
            $outputStream = [IO.File]::Open($file.Path, [IO.FileMode]::CreateNew)
            try { $inputStream.CopyTo($outputStream) } finally { $outputStream.Dispose(); $inputStream.Dispose() }
        }
    } finally { $zip.Dispose() }
}
function Assert-RuntimeFiles([string]$Root) {
    foreach ($name in @('Start-PulseRelay.cmd','scripts/Start-PulseRelay.ps1','scripts/realtek_8922.py','config.json','runtime/python/python.exe','runtime/sdk/emulator/emulator.exe','runtime/sdk/platform-tools/adb.exe','runtime/sdk/system-images/android-31/google_apis/x86_64/system.img','runtime/android-home/avd/PulseRelay12.avd/userdata-qemu.img.qcow2','runtime/android-home/avd/PulseRelay12.avd/qemu-version.txt')) {
        if (!(Test-Path -LiteralPath (Join-Path $Root $name) -PathType Leaf)) { throw "Runtime is incomplete: $name" }
    }
}
function Install-RuntimePatches([string]$PackageRoot, [string]$Root) {
    foreach ($name in @('Start-PulseRelay.ps1','Set-AndroidDefaults.ps1')) {
        Copy-Item -LiteralPath (Join-Path $PackageRoot "runtime-patches/$name") -Destination (Join-Path $Root "scripts/$name") -Force
    }
}
