
<#
.Synopsis
	Shows Invoke-Build task trees with brief information.
	Invoke-Build - Build Automation in PowerShell
	Copyright (c) 2011-2017 Roman Kuzmin

.Description
	This script analyses task references and shows parent tasks and child trees
	for the specified tasks. Tasks are not invoked.

	Invoke-Build.ps1 should be in the script directory or in the path.

.Parameter Task
		Task names.
		If it is "*" then all root tasks are used.
		If it is omitted or "." then the default task is used.
.Parameter File
		The build script.
		If it is omitted then the default script is used.
.Parameter Parameters
		Build script parameters needed in special cases when they alter tasks.
.Parameter Upstream
		Tells to show upstream tasks for each task.

.Inputs
	None.
.Outputs
	Specified task trees.

.Link
	https://github.com/nightroman/Invoke-Build
#>

param(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][hashtable]$Parameters,
	[switch]$Upstream
)

$private:_Task = $Task
$private:_File = $File
$private:_Parameters = if ($Parameters) {$Parameters} else {@{}}
$private:_Upstream = $Upstream
Remove-Variable Task, File, Parameters, Upstream

# Shows the task tree.
function ShowTaskTree($Task, $Docs, $Step = 0) {
	if ($Step -eq 0) {''}
	$tab = '    ' * $Step
	++$Step

	# synopsis
	$synopsis = *TS $Task.InvocationInfo $docs

	# name
	$info = $tab + $Task.Name

	# upstream
	if ($references.Count) {
		$reference = $references[$Task]
		if ($reference.Count) {
			$info += ' (' + (($reference.Keys | Sort-Object) -join ', ') + ')'
		}
	}

	# synopsis, output
	if ($synopsis) {"$info # $synopsis"} else {$info}

	# task jobs
	foreach($_ in $Task.Jobs) {
		if ($_ -is [string]) {
			ShowTaskTree $tasks[$_] $Docs $Step
		}
		else {
			$tab + '    {}'
		}
	}
}

# Task synopsis.
function *TS($I, $H) {
	$f = $I.ScriptName
	if (!($d = $H[$f])) {
		$H[$f] = $d = @{}
		foreach($_ in [System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $f), [ref]$null)) {
			if ($_.Type -eq 'Comment') {$d[$_.EndLine] = $_.Content}
		}
	}
	for($n = $I.ScriptLineNumber; --$n -ge 1 -and ($c = $d[$n])) {
		if ($c -match '(?m)^\s*#*\s*Synopsis\s*:\s*(.*)$') {return $Matches[1]}
	}
}

# To amend errors
try {
	# resolve Invoke-Build.ps1
	$ib = Get-Command "$(Split-Path $MyInvocation.MyCommand.Path)/Invoke-Build.ps1" -CommandType ExternalScript -ErrorAction 0
	if (!$ib) {
		$ib = Get-Command Invoke-Build.ps1 -CommandType ExternalScript -ErrorAction 0
		if (!$ib) {throw 'Cannot find Invoke-Build.ps1'}
	}

	# get tasks
	$tasks = & $ib ?? $_File @_Parameters

	# references
	$references = @{}
	if ($_Upstream) {
		foreach($it in $tasks.Values) {
			$references[$it] = @{}
		}
		foreach($it in $tasks.Values) {foreach($job in $it.Jobs) {if ($job -is [string]) {
			$references[$tasks[$job]][$it.Name] = 0
		}}}
	}

	# resolve task
	if ($_Task -eq '*') {
		$_Task = :task foreach($_ in $tasks.Keys) {
			foreach($task in $tasks.Values) {
				if ($task.Jobs -contains $_) {
					continue task
				}
			}
			$_
		}
	}
	elseif (!$_Task -or '.' -eq $_Task) {
		$_Task = if ($tasks['.']) {'.'} else {$tasks.Item(0).Name}
	}

	# test tasks
	foreach($name in $_Task) {
		if (!$tasks[$name]) {throw "Missing task '$name'."}
	}

	# show trees
	$docs = @{}
	foreach($name in $_Task) {
		ShowTaskTree $tasks[$name] $docs
	}
}
catch {
	if ($_.InvocationInfo.ScriptName -ne $MyInvocation.MyCommand.Path) {throw}
	$PSCmdlet.ThrowTerminatingError($_)
}
