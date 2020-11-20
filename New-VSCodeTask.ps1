<#PSScriptInfo
.VERSION 1.3.2
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) Roman Kuzmin
.TAGS Invoke, Task, Invoke-Build, VSCode
.GUID b8b2b532-28f6-443a-b0b1-079a66dd4ce3
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Makes VSCode tasks from Invoke-Build tasks and tasks-merge.json

.Description
	Change to your VSCode workspace directory before invoking this command.

	The script creates ".vscode/tasks.json" based on the Invoke-Build tasks and
	the optional "tasks-merge.json" tasks. Do not edit "tasks.json" directly.
	When you add, remove, rename tasks, change script locations, or modify
	"tasks-merge.json" then regenerate.

	The default task becomes the so called VSCode build task (Ctrl+Shift+B).
	The default task is "." if it exists, otherwise it is the first task.

	To invoke another task from VSCode, hit F1 or Ctrl+Shift+P, type "Run
	Task", type a task name or select it from the task list. Even better,
	set your keyboard shortcut for "workbench.action.tasks.runTask".

	Only tasks with certain names are included. They contain alphanumeric
	characters, "_", ".", and "-", with the first character other than "-".

.Parameter BuildFile
		Specifies the build script path, absolute or relative. By default it is
		the default script in the current location, i.e. in the workspace root.

.Parameter InvokeBuild
		Specifies Invoke-Build.ps1 path, absolute or relative. If it is omitted
		then any found in workspace is used. Otherwise, "Invoke-Build" is used.

.Parameter Shell
		Specifies the name or path of the powershell or pwsh executable.
		The default is "powershell.exe".

.Parameter Merge
		Specifies the tasks to be merged with the generated Invoke-Build tasks.
		The default is ".vscode/tasks-merge.json", it is merged automatically.
		The schema is the same as "tasks.json". The property "tasks" must be
		defined as the array of task objects. Other properties are not used.
		Lines starting with "//" are treated as comments and ignored.
		The tasks are added or merged with existing by properties.

.Parameter WhereTask
		Tells to filter tasks and specifies the filter script block. The script
		checks the task $_ and gets $true/$false in order to include/exclude.

.Example
	> New-VSCodeTask

	This command binds to the default build script in the workspace root and
	Invoke-Build.ps1 either in the workspace root or subdirectory or in the
	path or the module command.

.Example
	> New-VSCodeTask ./Scripts/Build.ps1 ./packages/InvokeBuild/Invoke-Build.ps1

	This command uses relative build and engine script paths. The second may be
	omitted, Invoke-Build.ps1 will be discovered. But it is needed if there may
	be several Invoke-Build.ps1 in the workspace.

.Example
	> New-VSCodeTask -WhereTask {$_.Name -notlike "_*" -and $_.Jobs.Count -ge 2}

	This command filters tasks and tells to exclude tasks like "_*" and include
	tasks with two or more jobs.
#>

[CmdletBinding()]
param(
	[string]$BuildFile,
	[string]$InvokeBuild,
	[string]$Shell = 'powershell.exe',
	[string]$Merge = '.vscode/tasks-merge.json',
	[scriptblock]$WhereTask
)

trap {Write-Error -ErrorRecord $_}
$ErrorActionPreference = 1

# resolve Invoke-Build.ps1
if (!$InvokeBuild) {
	$_ = @(Get-ChildItem . -Name -Recurse -Filter Invoke-Build.ps1)
	if ($_) {
		$InvokeBuild = './{0}' -f $_[0]
	}
	else {
		$InvokeBuild = 'Invoke-Build'
	}
}

# get all tasks and the default task
$all = & $InvokeBuild ?? -File $BuildFile
$dot = if ($all['.']) {'.'} else {$all.Item(0).Name}

# get inputs tasks, optionally filtered
if ($WhereTask) {
	$tasks1 = @($all.get_Values() | Where-Object $WhereTask)
}
else {
	$tasks1 = $all.get_Values()
}

### result task data
$tasks2 = [System.Collections.Generic.List[object]]@()
$data = [ordered]@{
	version = '2.0.0'
	windows = [ordered]@{
		options = [ordered]@{
			shell = [ordered]@{
				executable = $Shell
				args = '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command'
			}
		}
	}
	linux = [ordered]@{
		options = [ordered]@{
			shell = [ordered]@{
				executable = '/usr/bin/pwsh'
				args = '-NoProfile', '-Command'
			}
		}
	}
	osx = [ordered]@{
		options = [ordered]@{
			shell = [ordered]@{
				executable = '/usr/local/bin/pwsh'
				args = '-NoProfile', '-Command'
			}
		}
	}
	tasks = $tasks2
}

### add main tasks
$argIB = if ($InvokeBuild -eq 'Invoke-Build') {'Invoke-Build'} else {"& '{0}'" -f $InvokeBuild.Replace('\', '/').Replace("'", "''")}
$argFile = if ($BuildFile) {" -File '{0}'" -f $BuildFile.Replace('\', '/').Replace("'", "''")} else {''}
foreach($task1 in $tasks1) {
	$name = $task1.Name
	if ($name -match '[^\w\.\-]|^-') {
		continue
	}
	$task2 = [ordered]@{
		label = $name
		type = 'shell'
		command = '{0} -Task {1}{2}' -f $argIB, $name, $argFile
		problemMatcher = '$msCompile'
		presentation = [ordered]@{
			echo = $false
			showReuseMessage = $false
		}
	}
	if ($name -eq $dot) {
		$task2.group = [ordered]@{
			kind = 'build'
			isDefault = $true
		}
	}
	$tasks2.Add($task2)
}

### add help task
$task2 = [ordered]@{
	label = '?'
	type = 'shell'
	command = '{0} -Task ?{1}' -f $argIB, $argFile
	problemMatcher = '$msCompile'
	presentation = [ordered]@{
		echo = $false
		showReuseMessage = $false
	}
}
$tasks2.Add($task2)

### merge tasks
if ($Merge -and (Test-Path -LiteralPath $Merge)) {&{
	# read and replace line comments with empty lines, to preserve line numbers
	$lines = Get-Content -LiteralPath $Merge | .{process{if ($_ -match '^\s*//') {''} else {$_}}}
	Set-StrictMode -Off
	try {
		$json = $lines | ConvertFrom-Json
		if (!($mergeTasks = $json.tasks)) {
			throw "Missing required property 'tasks'."
		}
		foreach($task2 in $mergeTasks) {
			# get task label
			if (!($label = $task2.label)) {
				throw "Tasks must define 'label'."
			}

			# find existing task
			$task1 = $null
			foreach($_ in $tasks2) {
				if ($label -eq $_.label) {
					$task1 = $_
					break
				}
			}

			# merge existing task or add new
			if ($task1) {
				foreach($_ in $task2.PSObject.Properties) {
					$task1[$_.Name] = $_.Value
				}
			}
			else {
				$tasks2.Add($task2)
			}
		}
	}
	catch {
		throw "Cannot merge '$Merge': $_"
	}
}}

### save tasks.json
$Header1 = '// Do not edit! This file is generated by New-VSCodeTask.ps1'
$Header2 = '// Modify the build script or tasks-merge.json and recreate.'
if (!(Test-Path .vscode)) {
	$null = mkdir .vscode
}
elseif (Test-Path .vscode/tasks.json) {
	$line1, $null = Get-Content .vscode/tasks.json
	if ($line1 -ne $Header1) {
		Remove-Item .vscode/tasks.json -Confirm
		if (Test-Path .vscode/tasks.json) {
			return
		}
	}
}
$(
	$Header1
	$Header2
	ConvertTo-Json $data -Depth 99
) |
Set-Content .vscode/tasks.json -Encoding UTF8
