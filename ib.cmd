
@echo off
rem ib.cmd - Invoke-Build helper for cmd.exe
rem ib.cmd must be in the same directory as Invoke-Build.ps1

if "%1"=="?" goto list
if "%1"=="/?" goto help

PowerShell.exe -NoProfile -ExecutionPolicy Bypass "& '%~dp0Invoke-Build.ps1' %*"
exit /B %errorlevel%

:list
PowerShell.exe -NoProfile -ExecutionPolicy Bypass "& '%~dp0Invoke-Build.ps1' %* | Format-Table -AutoSize"
exit

:help
PowerShell.exe -NoProfile -ExecutionPolicy Bypass "help -Full '%~dp0Invoke-Build.ps1'"
exit
