param([ValidateSet('Zadig','Acceleration')][string]$Action)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
try {
    if ($Action -eq 'Zadig') {
        $process = Start-Process -FilePath (Join-Path $root 'tools/zadig-2.9.exe') -Verb RunAs -PassThru -Wait
        exit $process.ExitCode
    }
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $process = Start-Process powershell.exe -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$PSCommandPath+'"'),'-Action','Acceleration') -PassThru -Wait
        exit $process.ExitCode
    }
    Push-Location (Join-Path $root 'tools/aehd')
    try {
        & cmd.exe /d /c silent_install_safe.bat
        if ($LASTEXITCODE -ne 0) { throw 'AEHD installation failed. Enable CPU virtualization in BIOS; if Hyper-V is enabled use Windows Hypervisor Platform instead.' }
    } finally { Pop-Location }
    Write-Host 'Acceleration driver installation finished.'
} catch { Write-Host "Tool failed: $_"; exit 1 }
