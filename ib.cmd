:: Invoke-Build helper for cmd.exe

@echo off

if "%pwsh%"=="" set pwsh=powershell.exe
if "%1"=="/?" goto help

"%pwsh%" -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Build %*"
exit /B %errorlevel%

:help
"%pwsh%" -NoProfile -ExecutionPolicy Bypass -Command "help -Full Invoke-Build"
exit /B 0
