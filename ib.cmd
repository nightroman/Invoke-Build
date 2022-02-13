:: Invoke-Build helper for cmd.exe

@echo off

if "%1"=="/?" goto help

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Build %*"
exit /B %errorlevel%

:help
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "help -Full Invoke-Build"
exit /B 0
