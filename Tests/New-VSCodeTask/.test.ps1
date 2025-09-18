<#
.Synopsis
	Tests New-VSCodeTask.ps1
#>

Import-Module ..\Tools
Set-StrictMode -Off

function Import-Json($Path) {
	$text = Get-Content -LiteralPath $Path | .{process{if ($_ -match '^\s*//') {''} else {$_}}} | Out-String -Width 9999
	ConvertFrom-Json $text
}

function Get-Task($Data, $Name) {
	foreach($_ in $Data.Tasks) {
		if ($_.label -eq $Name) {
			return $_
		}
	}
}

# Synopsis: Use defaults and pretend merge is not there.
task Basic {
	New-VSCodeTask -Merge missing.json
	$data = Import-Json .vscode\tasks.json

	# default shell
	equals $data.windows.options.shell.executable powershell.exe

	# last task is ?
	equals $data.tasks[-1].label ?

	# default task
	$r = Get-Task $data .
	assert $r
	assert $r.group
	equals $r.group.kind build
	equals $r.group.isDefault $true
	equals $r.command 'Invoke-Build -Task .'

	# task Build is not default
	$r = Get-Task $data Build
	assert $r
	equals $r.group $null
	equals $r.command 'Invoke-Build -Task Build'
}

# Synopsis: Test custom shell and task filter.
task ParameterShellAndWhereTask {
	New-VSCodeTask -Shell ..\pwsh.exe -WhereTask {$_.Name -eq 'Build'} -Merge ''
	$data = Import-Json .vscode\tasks.json

	# custom shell
	equals $data.windows.options.shell.executable ..\pwsh.exe

	# filtered tasks
	equals $data.tasks.Count 2
	equals $data.tasks[0].label Build
	equals $data.tasks[1].label ?
}

# Synopsis: Test custom paths and exclude task conversions.
task FullPathsFirstDefaultIncludeExclude {
	$InvokeBuild = *Path ..\..\Invoke-Build.ps1
	New-VSCodeTask $BuildFile $InvokeBuild -Merge ''

	# default is the first task
	$data = Import-Json .vscode\tasks.json
	($r = $data.tasks[0]) | Out-String
	assert $r.group
	equals $r.group.kind build
	equals $r.group.isDefault $true
 	equals $r.command ("& '{0}' -Task Basic -File '{1}'" -f $InvokeBuild.Replace('\', '/'), $BuildFile.Replace('\', '/'))

	# =1= funny name is included
	$r = Get-Task $data ._w2-
	assert $r

	# =1= funny name is excluded
	$r = Get-Task $data '-name'
	equals $r
}

# Synopsis: Test relative paths..
task RelativePaths {
	New-VSCodeTask .\1.build.ps1 ..\..\Invoke-Build.ps1 -Merge ''

	$data = Import-Json .vscode\tasks.json
	$r = $data.tasks[0]
	$r.command
 	equals $r.command "& '../../Invoke-Build.ps1' -Task Build -File './1.build.ps1'"
}

# Synopsis: Case with the local Invoke-Build.ps1.
task DiscoverEngine {
	#! pretend we are in IB root
	Set-Location ..\..
	New-VSCodeTask

	$data = Import-Json .vscode\tasks.json
	$r = Get-Task $data .
	$r.command
	equals $r.command "& './Invoke-Build.ps1' -Task ."

	#! in IB root
	remove .vscode
}

# Synopsis: No merge (here tell not to use default).
task NoMerge {
	New-VSCodeTask -Merge ''
	$data = Import-Json .vscode\tasks.json

	# no Merge1
	$r = Get-Task $data Merge1
	equals $r $null

	# help task is not changed
	$r = Get-Task $data ?
	equals $r.runOptions $null

	Remove-Item .vscode\tasks.json
}

# Synopsis: With merge (here just use default).
task WithMerge {
	New-VSCodeTask
	$data = Import-Json .vscode\tasks.json

	# new Merge1
	$r = Get-Task $data Merge1
	assert $r

	# help task is changed
	$r = Get-Task $data ?
	equals $r.runOptions.reevaluateOnRerun $true

	Remove-Item .vscode\tasks.json
}

# Synopsis: Merge file with no tasks.
task BadMergeNoTasks {
	Set-Content z.json '{}'
	($r = try {New-VSCodeTask -Merge z.json} catch {$_})
	equals $r.FullyQualifiedErrorId "Cannot merge 'z.json': Missing required property 'tasks'.,New-VSCodeTask.ps1"
	remove z.json
}

# Synopsis: Merge task with no label.
task BadMergeTaskNoLabel {
	Set-Content z.json '{tasks: [{}]}'
	($r = try {New-VSCodeTask -Merge z.json} catch {$_})
	equals $r.FullyQualifiedErrorId "Cannot merge 'z.json': Tasks must define 'label'.,New-VSCodeTask.ps1"
	remove z.json
}

# Other tasks are not real tests
if (!$WhatIf) {return}

# This task is included, see =1=
task ._w2-

# This task is excluded, see =1=
task '-name'
