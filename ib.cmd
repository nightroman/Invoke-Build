
:: ib.cmd - Invoke-Build helper for cmd.exe
:: It must be in the same directory as Invoke-Build.ps1

@echo off

if "%1"=="?" goto list
if "%1"=="/?" goto help

PowerShell.exe -NoProfile -ExecutionPolicy Bypass "& '%~dp0Invoke-Build.ps1' %*"
exit /B %errorlevel%

:list
PowerShell.exe -NoProfile -ExecutionPolicy Bypass "& '%~dp0Invoke-Build.ps1' %* | Format-Table -AutoSize"
exit /B 0

:help
PowerShell.exe -NoProfile -ExecutionPolicy Bypass "help -Full '%~dp0Invoke-Build.ps1'"
exit /B 0
