
<#
.Synopsis
	Tests and shows hows to use New-VSCodeTask.ps1
#>

# ConvertFrom-Json is v3+
if ($PSVersionTable.PSVersion.Major -lt 3) {return task v2}

function Get-Json {
	$1, $2, $3 = Get-Content .vscode\tasks.json
	$r = ConvertFrom-Json ($3 | Out-String)
	equals $r.command .\.vscode\tasks.cmd
	equals $r.suppressTaskName $false
	equals $r.showOutput always
	$r
}

function Test-Json {
	'Test-Json'
	$r = Get-Json

	# (*) tasks included/excluded
	equals $r.tasks[-2].taskName ._w2-

	# default is the first and the only
	equals $r.tasks[0].taskName OmittedPaths
	$r2 = $r.tasks | Select-Object taskName, isBuildCommand | .{process{ if ($_.isBuildCommand) {$_} }}
	equals $r2.taskName OmittedPaths

	# console host tasks
	$r2 = $r.tasks | Select-Object taskName, args, suppressTaskName | .{process{ if ($_.args -and $_.suppressTaskName) {$_} }}
	equals $r2.Count 3
	equals $r2[0].taskName ConsoleHost1
	equals $r2[1].taskName ConsoleHost2
	equals $r2[2].taskName ConsoleHost3
}

task OmittedPaths {
	New-VSCodeTask.ps1

	$r = (Get-Content .vscode\tasks.cmd) -match 'PowerShell\.exe'
	equals $r.Count 2
	equals $r[0] @'
PowerShell.exe -NoProfile -ExecutionPolicy Bypass "& 'Invoke-Build.ps1' %1"
'@
	equals $r[1] @'
start PowerShell.exe -NoExit -NoProfile -ExecutionPolicy Bypass "& 'Invoke-Build.ps1' %1"
'@

	$r = Get-Json
	$r = $r.tasks | Select-Object taskName, isBuildCommand | .{process{ if ($_.isBuildCommand) {$_} }}
	equals $r.taskName .

	Remove-Item .vscode -Force -Recurse
}

task FullPaths {
	$InvokeBuild = *FP ..\Invoke-Build.ps1
	New-VSCodeTask.ps1 $BuildFile $InvokeBuild

	$r = (Get-Content .vscode\tasks.cmd) -match 'PowerShell\.exe'
	equals $r.Count 2
	equals $r[0] @"
PowerShell.exe -NoProfile -ExecutionPolicy Bypass "& '$InvokeBuild' -File '$BuildFile' %1"
"@
	equals $r[1] @"
start PowerShell.exe -NoExit -NoProfile -ExecutionPolicy Bypass "& '$InvokeBuild' -File '$BuildFile' %1"
"@

	Test-Json
	Remove-Item .vscode -Force -Recurse
}

task RelativePaths {
	New-VSCodeTask.ps1 .\VSCode.test.ps1 ..\Invoke-Build.ps1

	$r = (Get-Content .vscode\tasks.cmd) -match 'PowerShell\.exe'
	equals $r.Count 2
	equals $r[0] @'
PowerShell.exe -NoProfile -ExecutionPolicy Bypass "& '..\Invoke-Build.ps1' -File '.\VSCode.test.ps1' %1"
'@
	equals $r[1] @'
start PowerShell.exe -NoExit -NoProfile -ExecutionPolicy Bypass "& '..\Invoke-Build.ps1' -File '.\VSCode.test.ps1' %1"
'@

	Test-Json
	Remove-Item .vscode -Force -Recurse
}

task DiscoverEngine {
	Set-Location ..
	New-VSCodeTask.ps1

	$r = (Get-Content .vscode\tasks.cmd) -match 'PowerShell\.exe'
	equals $r.Count 2
	equals $r[0] @'
PowerShell.exe -NoProfile -ExecutionPolicy Bypass "& '.\Invoke-Build.ps1' %1"
'@
	equals $r[1] @'
start PowerShell.exe -NoExit -NoProfile -ExecutionPolicy Bypass "& '.\Invoke-Build.ps1' %1"
'@

	Remove-Item .vscode -Force -Recurse
}

# Other tasks are not real tests
if (!$WhatIf) {return}

#ConsoleHost
task ConsoleHost1
task ConsoleHost2 ConsoleHost1
task ConsoleHost3 ConsoleHost2

# This task is included, see (*)
task ._w2- -if 0

# This task is excluded, see (*)
task '-name' -if 0
