:: Invoke-Build helper for cmd.exe

@echo off

if "%1"=="?" goto list
if "%1"=="/?" goto help

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Build %*"
exit /B %errorlevel%

:list
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Build ? | Format-Table -AutoSize"
exit /B 0

:help
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "help -Full Invoke-Build"
exit /B 0
