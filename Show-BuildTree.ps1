
<#
.Synopsis
	Shows Invoke-Build task trees with optional comments.
	Invoke-Build - Build Automation in PowerShell
	Copyright (c) 2011-2014 Roman Kuzmin

.Description
	This script analyses task references and shows parent tasks and child trees
	for the specified tasks. Tasks are not invoked. Use the switch Comment in
	order to show preceding task comments as well.

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
.Parameter Comment
		Tells to show task code comments in task trees.

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
	[switch]$Comment
)

$private:_Task = $Task
$private:_File = $File
$private:_Parameters = $Parameters
$private:_Comment = $Comment
Remove-Variable Task, File, Parameters, Comment

# Shows the task tree.
function ShowTaskTree($Task, $Comment, $Step = 0) {
	if ($Step -eq 0) {''}
	$tab = '    ' * $Step
	++$Step

	# comment
	if ($Comment) {
		foreach($_ in GetTaskComment $Task) {
			if ($_) {$tab + $_}
		}
	}

	# name, parents
	$info = $tab + $Task.Name
	$reference = $references[$Task]
	if ($reference.Count) {
		$info += ' (' + (($reference.Keys | Sort-Object) -join ', ') + ')'
	}
	$info

	# task jobs
	foreach($_ in $Task.Job) {
		if ($_ -is [string]) {
			ShowTaskTree $tasks[$_] $Comment $Step
		}
		else {
			$tab + '    {}'
		}
	}
}

# Gets comments.
$file2docs = @{}
function GetTaskComment($Task) {
	$file = $Task.InvocationInfo.ScriptName
	$docs = $file2docs[$file]
	if (!$docs) {
		$docs = New-Object System.Collections.Specialized.OrderedDictionary
		$file2docs[$file] = $docs
		foreach($token in [System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $file), [ref]$null)) {
			if ($token.Type -eq 'Comment') {
				$docs[[object]$token.EndLine] = $token.Content
			}
		}
	}
	$rem = ''
	for($1 = $Task.InvocationInfo.ScriptLineNumber - 1; $1 -ge 1; --$1) {
		$doc = $docs[[object]$1]
		if (!$doc) {break}
		$rem = $doc.Replace("`t", '    ') + "`n" + $rem
	}
	[regex]::Split($rem.TrimEnd(), '[\r\n]+')
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
	foreach($name in $_Task) {
		ShowTaskTree $tasks[$name] $_Comment
	}
}
catch {
	if ($_.InvocationInfo.ScriptName -ne $MyInvocation.MyCommand.Path) {throw}
	$PSCmdlet.ThrowTerminatingError($_)
}
