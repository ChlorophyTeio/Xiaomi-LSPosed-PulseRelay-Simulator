@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Install-Online.ps1" %*
set "installExitCode=%errorlevel%"
echo.
pause
exit /b %installExitCode%
