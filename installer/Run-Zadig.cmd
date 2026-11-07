@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Run-Tool.ps1" -Action Zadig
pause
