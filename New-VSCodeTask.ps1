
<#PSScriptInfo
.VERSION 1.1.3
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) 2011-2017 Roman Kuzmin
.TAGS Invoke, Task, Invoke-Build, VSCode
.GUID b8b2b532-28f6-443a-b0b1-079a66dd4ce3
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Makes VSCode tasks from Invoke-Build tasks

.Description
	The script creates "./.vscode/tasks.json". The existing file is replaced.
	Change to the VSCode workspace directory before invoking the script.
	Generated VSCode tasks call Invoke-Build tasks.

	Do not edit "tasks.json" directly. Edit the build script instead. When you
	add, remove, rename tasks, or change script locations then regenerate.

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
		Specifies the Invoke-Build.ps1 path, absolute or relative. If it is not
		specified then any found in the workspace is used. If there is none
		then the command Invoke-Build is used.

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
#>

[CmdletBinding()]
param(
	[string]$BuildFile,
	[string]$InvokeBuild
)

function Add-Text($Text) {$null = $out.Append($Text)}
function Add-Line($Text) {$null = $out.AppendLine($Text)}

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 'Stop'

# resolve Invoke-Build.ps1
if (!$InvokeBuild) {
	$InvokeBuild2 = @(Get-ChildItem . -Name -Recurse -Filter Invoke-Build.ps1)
	$InvokeBuild = if ($InvokeBuild2) {
		'./{0}' -f $InvokeBuild2[0]
	} else {
		'Invoke-Build'
	}
}
$InvokeBuild2 = if ($InvokeBuild -eq 'Invoke-Build') {
	'Invoke-Build'
}
else {
	"& '{0}'" -f $InvokeBuild.Replace('\', '/').Replace("'", "''")
}

# get all tasks and the default task
$all = & $InvokeBuild ?? -File $BuildFile
$dot = if ($all['.']) {'.'} else {$all.Item(0).Name}

# tasks.json header
$out = New-Object System.Text.StringBuilder
Add-Line '// Do not edit! This file is generated by New-VSCodeTask.ps1'
Add-Line '// Modify the build script instead and regenerate this file.'
Add-Line '{'
Add-Line '  "version": "2.0.0",'
Add-Line '  "suppressTaskName": true,'
Add-Line '  "windows": {'
Add-Line '    "command": "powershell.exe",'
Add-Line '    "args": [ "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command" ]'
Add-Line '  },'
Add-Line '  "linux": {'
Add-Line '    "command": "/usr/bin/pwsh",'
Add-Line '    "args": [ "-NoProfile", "-Command" ]'
Add-Line '  },'
Add-Line '  "osx": {'
Add-Line '    "command": "/usr/local/bin/pwsh",'
Add-Line '    "args": [ "-NoProfile", "-Command" ]'
Add-Line '  },'
Add-Line '  "tasks": ['

# tasks.json tasks
$BuildFile2 = if ($BuildFile) {" -File '{0}'" -f $BuildFile.Replace('\', '/').Replace("'", "''")} else {''}
foreach($task in $all.Values) {
	$name = $task.Name
	if ($name -match '[^\w\.\-]|^-') {
		continue
	}
	Add-Line '    {'
	Add-Line ('      "taskName": "{0}",' -f $name)
	Add-Line '      "problemMatcher": ['
	Add-Line '        "$msCompile"'
	Add-Line '      ],'
	if ($name -eq $dot) {
		Add-Line '      "group": {'
		Add-Line '        "kind": "build",'
		Add-Line '        "isDefault": true'
		Add-Line '      },'
	}
	Add-Line ('      "args": [ "{0} -Task {1}{2}" ]' -f $InvokeBuild2, $name, $BuildFile2)
	Add-Line '    },'
}

# last task and ending
Add-Line '    {'
Add-Line '      "taskName": "?",'
Add-Line '      "problemMatcher": [],'
Add-Line ('      "args": [ "{0} -Task ?{1}" ]' -f $InvokeBuild2, $BuildFile2)
Add-Line '    }'
Add-Line '  ]'
Add-Text '}'

# save the file
if (!(Test-Path .vscode)) {
	$null = mkdir .vscode
}
Set-Content ./.vscode/tasks.json $out.ToString() -Encoding UTF8
