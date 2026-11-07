@echo off
if not exist "%~dp0download-settings.json" copy /y "%~dp0download-settings.example.json" "%~dp0download-settings.json" >nul
notepad.exe "%~dp0download-settings.json"
