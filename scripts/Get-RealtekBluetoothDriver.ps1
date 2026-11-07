# ASUS ROG STRIX B850-G GAMING WIFI S / Realtek RTL8922AE.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$destination = Join-Path $root 'runtime/realtek-bluetooth'
$expectedHash = 'C4346316B2F8EB7F2E13BDC70C05687E14315EF8FCE2435449CD817E5A93FAA2'
$archive = Join-Path $root 'runtime/realtek-bluetooth.zip'
$url = 'https://dlcdnets.asus.com/pub/ASUS/mb/02BT/DRV_BT_RTK_8922AE_SZ-TSD_W11_64_V246404126031202_20260804R.zip'
New-Item -ItemType Directory -Force -Path (Join-Path $root 'runtime') | Out-Null
if (!(Test-Path -LiteralPath $archive) -or (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedHash) {
    Write-Host 'Downloading the ASUS Realtek Bluetooth driver (about 3 MB)...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $archive
}
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'ASUS Bluetooth driver checksum mismatch. Driver installation cancelled.'
}
Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
if (!(Test-Path -LiteralPath (Join-Path $destination 'x64/rtkbtfilter.inf'))) {
    throw 'ASUS Bluetooth driver archive is missing rtkbtfilter.inf.'
}
