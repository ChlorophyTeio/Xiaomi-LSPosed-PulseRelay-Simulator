#Requires -RunAsAdministrator
. "$PSScriptRoot/Common.ps1"
& $Emulator -accel-check
if ($LASTEXITCODE -ne 0) {
    Push-Location (Join-Path $ProjectRoot 'runtime/aehd')
    try { & .\silent_install_safe.bat } finally { Pop-Location }
    & $Emulator -accel-check
    if ($LASTEXITCODE -ne 0) { throw 'Acceleration unavailable. Enable CPU virtualization in BIOS. If Hyper-V is in use, enable Windows Hypervisor Platform and restart Windows.' }
}
Write-Output 'Acceleration is ready. Configure your Bluetooth adapter next.'
