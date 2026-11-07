param([string]$DownloadDirectory = '.', [string]$OutputPath = '')
$ErrorActionPreference = 'Stop'
$directory = (Resolve-Path -LiteralPath $DownloadDirectory).Path
if (!$OutputPath) { $OutputPath = Join-Path $directory 'PulseRelay-Windows-Clean.zip' }
if (Test-Path -LiteralPath $OutputPath) { throw 'Output exists; choose another OutputPath.' }
$parts = @(Get-ChildItem -LiteralPath $directory -Filter 'PulseRelay-Windows-Clean.zip.part???' | Sort-Object Name)
if ($parts.Count -ne 4) { throw 'Download all four parts (part001 through part004).' }
$stream = [IO.File]::Create($OutputPath)
try { foreach ($part in $parts) { $inputStream = [IO.File]::OpenRead($part.FullName); try { $inputStream.CopyTo($stream) } finally { $inputStream.Dispose() } } } finally { $stream.Dispose() }
$expected = ((Get-Content -LiteralPath (Join-Path $directory 'PulseRelay-Windows-Clean.zip.sha256') -Raw) -split '\s+')[0]
if ((Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash -ne $expected) { throw 'SHA256 mismatch. Download the parts again.' }
Write-Output "Verified: $OutputPath"
