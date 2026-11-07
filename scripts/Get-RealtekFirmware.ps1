$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$path = Join-Path $root 'runtime/rtl8922au_fw.bin'
$hash = '112290CA9DC3985034F572594812F0DEB8530DD031686461B55CAC43A1C35A79'
if (!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $hash) {
    New-Item -ItemType Directory -Force -Path (Join-Path $root 'runtime') | Out-Null
    Write-Host 'Downloading Realtek RTL8922 Bluetooth firmware...'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing -Uri 'https://gitlab.com/kernel-firmware/linux-firmware/-/raw/main/rtl_bt/rtl8922au_fw.bin' -OutFile $path
}
if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $hash) { throw 'RTL8922 firmware checksum mismatch. Startup cancelled.' }
