@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Apply-FullPackage-Update.ps1" %*
set "updateExitCode=%errorlevel%"
echo.
pause
exit /b %updateExitCode%
