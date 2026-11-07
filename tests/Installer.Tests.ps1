param([string]$WorkDirectory = '')
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
. "$repo/installer/scripts/Installer-Core.ps1"
if (!$WorkDirectory) { $WorkDirectory=Join-Path $repo ('runtime/installer-tests-'+[guid]::NewGuid().ToString('N')) }
New-Item -ItemType Directory -Force -Path $WorkDirectory | Out-Null
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
function New-Fixture([string]$Path,[string[]]$Names) {
    $zip=[IO.Compression.ZipFile]::Open($Path,[IO.Compression.ZipArchiveMode]::Create)
    try { foreach($name in $Names) { $entry=$zip.CreateEntry($name);$writer=New-Object IO.StreamWriter($entry.Open());try{$writer.Write('fixture')}finally{$writer.Dispose()} } } finally { $zip.Dispose() }
}
$valid=Join-Path $WorkDirectory 'valid.zip'
New-Fixture $valid @('Payload/config.json','Payload/dir/file.txt')
$validOutput=Join-Path $WorkDirectory 'valid'
Expand-PayloadArchive $valid $validOutput 'Payload'
if ((Get-Content -LiteralPath (Join-Path $validOutput 'dir/file.txt') -Raw) -ne 'fixture') { throw 'Valid extraction failed' }
$bad=Join-Path $WorkDirectory 'bad.zip'
New-Fixture $bad @('Payload/../escaped.txt')
$rejected=$false
try { Expand-PayloadArchive $bad (Join-Path $WorkDirectory 'bad') 'Payload' } catch { $rejected=$true }
if (!$rejected -or (Test-Path -LiteralPath (Join-Path $WorkDirectory 'escaped.txt'))) { throw 'Archive traversal was not rejected' }
$hash=(Get-FileHash -LiteralPath $valid -Algorithm SHA256).Hash
if (!(Test-PayloadFile $valid (Get-Item $valid).Length $hash)) { throw 'Valid hash was rejected' }
if (Test-PayloadFile $valid (Get-Item $valid).Length ('0'*64)) { throw 'Invalid hash was accepted' }
$long=Join-Path $WorkDirectory 'long.zip'
$relative=(('long-directory-name/'*12)+'file.txt')
New-Fixture $long @('Payload/'+$relative)
Expand-PayloadArchive $long (Join-Path $WorkDirectory 'long') 'Payload'
Write-Host 'PASS: extraction, archive traversal rejection, checksum validation, and long paths.'
