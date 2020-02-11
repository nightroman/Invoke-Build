
:: ib.cmd - Invoke-Build helper for cmd.exe
:: It must be in the same directory as Invoke-Build.ps1

@echo off

if "%1"=="?" goto list
if "%1"=="/?" goto help

rem Dot-source Invoke-Build first, so that it will be available in script block closures (#160)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0Invoke-Build.ps1'; Invoke-Build %*"
exit /B %errorlevel%

:list
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0Invoke-Build.ps1'; Invoke-Build %* | Format-Table -AutoSize"
exit /B 0

:help
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Help -Full '%~dp0Invoke-Build.ps1'"
exit /B 0
