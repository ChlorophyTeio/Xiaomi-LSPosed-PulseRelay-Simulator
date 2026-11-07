param([string]$DownloadDirectory = '.', [string]$OutputPath = '')
$ErrorActionPreference = 'Stop'
$directory = (Resolve-Path -LiteralPath $DownloadDirectory).Path
if (!$OutputPath) { $OutputPath = Join-Path $directory 'PulseRelay-Windows-Clean.zip' }
if (Test-Path -LiteralPath $OutputPath) { throw 'Output exists; choose another OutputPath.' }
$parts = @(Get-ChildItem -LiteralPath $directory -Filter 'PulseRelay-Windows-Clean.zip.part???' | Sort-Object Name)
if (!$parts.Count) { throw 'Download all release parts (part001, part002, ...) into the same folder.' }
for ($i = 0; $i -lt $parts.Count; $i++) {
    if ($parts[$i].Name -ne ('PulseRelay-Windows-Clean.zip.part{0:D3}' -f ($i + 1))) { throw 'Release parts are missing. Download every part in order.' }
}
$stream = [IO.File]::Create($OutputPath)
try { foreach ($part in $parts) { $inputStream = [IO.File]::OpenRead($part.FullName); try { $inputStream.CopyTo($stream) } finally { $inputStream.Dispose() } } } finally { $stream.Dispose() }
$expected = ((Get-Content -LiteralPath (Join-Path $directory 'PulseRelay-Windows-Clean.zip.sha256') -Raw) -split '\s+')[0]
if ((Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash -ne $expected) { throw 'SHA256 mismatch. Download the parts again.' }
Write-Output "Verified: $OutputPath"
