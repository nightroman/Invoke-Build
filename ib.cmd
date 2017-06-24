
:: ib.cmd - Invoke-Build helper for cmd.exe
:: It must be in the same directory as Invoke-Build.ps1

@echo off

if "%1"=="?" goto list
if "%1"=="/?" goto help

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0Invoke-Build.ps1' %*"
exit /B %errorlevel%

:list
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0Invoke-Build.ps1' %* | Format-Table -AutoSize"
exit /B 0

:help
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "help -Full '%~dp0Invoke-Build.ps1'"
exit /B 0
