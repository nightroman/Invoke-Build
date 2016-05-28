
<#
.Synopsis
	Tests and shows hows to use New-VSCodeTask.ps1
#>

# ConvertFrom-Json is v3+
if ($PSVersionTable.PSVersion.Major -lt 3) {return task v2}

function Get-Json {
	$1, $2, $3 = Get-Content .vscode\tasks.json
	$r = ConvertFrom-Json ($3 | Out-String)
	equals $r.command PowerShell.exe
	equals $r.args[0] '-NoProfile'
	equals $r.args[1] '-ExecutionPolicy'
	equals $r.args[2] Bypass
	$r
}

task OmittedPaths {
	New-VSCodeTask.ps1

	$r = Get-Json
	equals $r.args[3] Invoke-Build.ps1

	$r = $r.tasks | Select-Object taskName, isBuildCommand | .{process{ if ($_.isBuildCommand) {$_} }}
	equals $r.taskName .

	Remove-Item .vscode -Force -Recurse
}

task FullPaths {
	$InvokeBuild = *FP ..\Invoke-Build.ps1
	New-VSCodeTask.ps1 $BuildFile $InvokeBuild

	$r = Get-Json
	equals $r.args[3] $InvokeBuild
	equals $r.args[4] '-File'
	equals $r.args[5] $BuildFile

	# (*) task included
	equals $r.tasks[-2].taskName ._w2-

	$r = $r.tasks | Select-Object taskName, isBuildCommand | .{process{ if ($_.isBuildCommand) {$_} }}
	equals $r.taskName OmittedPaths

	Remove-Item .vscode -Force -Recurse
}

task RelativePaths {
	New-VSCodeTask.ps1 .\VSCode.test.ps1 ..\Invoke-Build.ps1

	$r = Get-Json
	equals $r.args[3] ..\Invoke-Build.ps1
	equals $r.args[4] '-File'
	equals $r.args[5] .\VSCode.test.ps1

	$r = $r.tasks | Select-Object taskName, isBuildCommand | .{process{ if ($_.isBuildCommand) {$_} }}
	equals $r.taskName OmittedPaths

	Remove-Item .vscode -Force -Recurse
}

# This task is included, see (*)
task ._w2- -if 0

# This task is excluded, see (*)
task '-name' -if 0
