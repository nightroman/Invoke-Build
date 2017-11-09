
<#
.Synopsis
	Tests and shows hows to use New-VSCodeTask.ps1
#>

# ConvertFrom-Json is v3+
if ($PSVersionTable.PSVersion.Major -lt 3) {return task v2}

function Get-Json {
	$1, $2, $3 = Get-Content .vscode\tasks.json
	ConvertFrom-Json ($3 | Out-String)
}

function Get-BuildTask($Tasks) {
	Set-StrictMode -Off
	foreach ($task in $Tasks) {
		if ($group = $task.group) {
			equals $group.kind build
			equals $group.isDefault $true
			$task
		}
	}
}

function Test-Json {
	'Test-Json'
	$r = Get-Json

	# the last is ?
	equals $r.tasks[-1].label ?

	# (*) tasks included/excluded
	equals $r.tasks[-2].label ._w2-

	# default is the first and the only
	equals $r.tasks[0].label OmittedPaths
	$r2 = Get-BuildTask $r.tasks
	equals $r2.label OmittedPaths
}

task OmittedPaths {
	New-VSCodeTask.ps1

	$r = Get-Json
	$t = Get-BuildTask $r.tasks
	equals $t.label .
 	equals $t.command 'Invoke-Build -Task .'

	Remove-Item .vscode -Force -Recurse
}

task FullPaths {
	$InvokeBuild = *Path ..\Invoke-Build.ps1
	New-VSCodeTask.ps1 $BuildFile $InvokeBuild

	$r = Get-Json
	$t = Get-BuildTask $r.tasks
	equals $t.label OmittedPaths
 	equals $t.command ("& '{0}' -Task OmittedPaths -File '{1}'" -f $InvokeBuild.Replace('\', '/'), $BuildFile.Replace('\', '/'))

	Test-Json
	Remove-Item .vscode -Force -Recurse
}

task RelativePaths {
	New-VSCodeTask.ps1 .\VSCode.test.ps1 ..\Invoke-Build.ps1

	$r = Get-Json
	$t = Get-BuildTask $r.tasks
	equals $t.label OmittedPaths
 	equals $t.command "& '../Invoke-Build.ps1' -Task OmittedPaths -File './VSCode.test.ps1'"

	Test-Json
	Remove-Item .vscode -Force -Recurse
}

task DiscoverEngine {
	Set-Location ..
	New-VSCodeTask.ps1

	$r = Get-Json
	$t = Get-BuildTask $r.tasks
	equals $t.label .
 	equals $t.command "& './Invoke-Build.ps1' -Task ."

	Remove-Item .vscode -Force -Recurse
}

# Other tasks are not real tests
if (!$WhatIf) {return}

# This task is included, see (*)
task ._w2- -if 0

# This task is excluded, see (*)
task '-name' -if 0
