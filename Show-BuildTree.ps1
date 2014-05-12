
<#
.Synopsis
	Shows Invoke-Build task trees with brief information.
	Invoke-Build - Build Automation in PowerShell
	Copyright (c) 2011-2014 Roman Kuzmin

.Description
	This script analyses task references and shows parent tasks and child trees
	for the specified tasks. Tasks are not invoked.

.Parameter Task
		Task names.
		If it is "*" then all root tasks are used.
		If it is omitted or "." then the default task is used.
.Parameter File
		The build script.
		If it is omitted then the default script is used.
.Parameter Parameters
		Build script parameters.
		They are needed only if they alter build trees.

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
	[Parameter(Position=2)][hashtable]$Parameters
)

$private:_Task = $Task
$private:_File = $File
$private:_Parameters = $Parameters
Remove-Variable Task, File, Parameters

# Shows the task tree.
function ShowTaskTree($Task, $Docs, $Step = 0) {
	if ($Step -eq 0) {''}
	$tab = '    ' * $Step
	++$Step

	# synopsis
	$synopsis = *TS $Task.InvocationInfo $docs

	# name, parents
	$info = $tab + $Task.Name
	$reference = $references[$Task]
	if ($reference.Count) {
		$info += ' (' + (($reference.Keys | Sort-Object) -join ', ') + ')'
	}
	if ($synopsis) {"$info - $synopsis"} else {$info}

	# task jobs
	foreach($_ in $Task.Job) {
		if ($_ -is [string]) {
			ShowTaskTree $tasks[$_] $Docs $Step
		}
		else {
			$tab + '    {}'
		}
	}
}

# Gets task synopsis.
function *TS($I, $M) {
	$f = $I.ScriptName
	if (!($d = $M[$f])) {
		$d = New-Object System.Collections.Specialized.OrderedDictionary
		$M[$f] = $d
		foreach($_ in [System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $f), [ref]$null)) {
			if ($_.Type -eq 'Comment') {
				$d[[object]$_.EndLine] = $_.Content
			}
		}
	}
	for($n = $I.ScriptLineNumber - 1; $n -ge 1; --$n) {
		if (!($c = $d[[object]$n])) {break}
		if ($c -match '(?m)^\s*#*\s*Synopsis\s*:\s*(.*)$') {return $Matches[1]}
	}
}


# To amend errors
try {
	# get tasks
	$tasks = Invoke-Build ?? -File:$_File -Parameters:$_Parameters

	# references
	$references = @{}
	foreach($it in $tasks.Values) {
		$references[$it] = @{}
	}
	foreach($it in $tasks.Values) {foreach($job in $it.Job) {if ($job -is [string]) {
		$references[$tasks[$job]][$it.Name] = 0
	}}}

	# resolve task
	if ($_Task -eq '*') {
		$_Task = :task foreach($_ in $tasks.Keys) {
			foreach($task in $tasks.Values) {
				if ($task.Job -contains $_) {
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
