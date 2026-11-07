@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Restore-WindowsBluetooth.ps1"
set "restoreExitCode=%errorlevel%"
echo.
pause
exit /b %restoreExitCode%
