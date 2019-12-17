
<#PSScriptInfo
.VERSION 1.1.8
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) Roman Kuzmin
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
.Parameter OnlyJobs
    Only generate tasks for job definitions. These are task definitions that compromise more than one individual task.
    This is useful when you are wrap up a bunch of small tasks that need some build variables or other steps and you don't really want to call tasks by themselves, only defined sets of tasks.

.Parameter Core
    Instead of defaulting to powershell.exe, use pwsh as the executable

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
    PS > . New-VSCodeTask ./build/build.tasks.ps1 -Core -OnlyJobs
    This would run relative path build tasks, replace powershell.exe with pwsh.exe for Windows. Finally it would filter down the task list to
    defined jobs instead of every individual task. This can be useful if you have a lot of small individual tasks that need to be wrapped up in jobs.

    This would change the task generation behavior from including the following single item of RebuildVSCodeTask, or dev_rebuild_vscode_tasks.
    PS> task RebuildVSCodeTask dev_rebuild_vscode_tasks

    However, the following would correctly show up as it contains more than 1 task
    PS> task RebuildVSCodeTask clean, dev_rebuild_vscode_tasks
#>

[CmdletBinding()]
param(
    [string]$BuildFile,
    [string]$InvokeBuild,
    [switch]$OnlyJobs,
    [switch]$Core
)

function Add-Text([string]$Text) { if ($args) { $out.Write($Text, $args) } else { $out.Write($Text) } }
function Add-Line([string]$Text) { if ($args) { $out.WriteLine($Text, $args) } else { $out.WriteLine($Text) } }

trap { $PSCmdlet.ThrowTerminatingError($_) }
$ErrorActionPreference = 'Stop'

# resolve Invoke-Build.ps1
if (!$InvokeBuild)
{
    $InvokeBuild2 = @(Get-ChildItem . -Name -Recurse -Filter Invoke-Build.ps1)
    $InvokeBuild = if ($InvokeBuild2)
    {
        './{0}' -f $InvokeBuild2[0]
    }
    else
    {
        'Invoke-Build'
    }
}
$InvokeBuild2 = if ($InvokeBuild -eq 'Invoke-Build')
{
    'Invoke-Build'
}
else
{
    "& '{0}'" -f $InvokeBuild.Replace('\', '/').Replace("'", "''")
}



if ($OnlyJobs)
{
####################################################
# If Requesting Only Jobs Then Filter Down Results #
#  To Just Those Containing More Than 1 Job Item   #
####################################################
    Write-Verbose "Filtering tasks to jobs containing more than 1 defined task in them"
    $all = (& $InvokeBuild ?? -File $BuildFile | Where-Object { @($_.Values.GetEnumerator().Jobs).Count -gt 1 }).GetEnumerator() | ForEach-Object {
        $v = $_
        $v.value  | Add-Member -NotePropertyName JobCount -NotePropertyValue (@($v.Value.Jobs).Count) -PassThru
    } | Where-Object { $_.JobCount -gt 1} | ForEach-Object {
        $i = $_
        $ht = @{ }
        $i.psobject.properties | ForEach-Object { $ht[$_.Name] = $_.Value }
        [hashtable]$Final = @{}
        $final.Add($i.Name, $ht)
        $final
    }
    Write-Verbose "$(@($All).Count) tasks discovered"
}
else
{
    ##############################
    # Default Behavior All Tasks #
    ##############################
    Write-Verbose "No filtering applied to task list. All discovered tasks included"
    $all = & $InvokeBuild ?? -File $BuildFile
    Write-Verbose "$(@($All).Count) tasks discovered"
}



$dot = if ($all['.']) { '.' } else { $all.Item(0).Name }

# tasks.json header
$out = New-Object System.IO.StringWriter
$Header = '// Do not edit! This file is generated by New-VSCodeTask.ps1'
Add-Line $Header
Add-Line '// Modify the build script instead and regenerate this file.'
Add-Line '{'
Add-Line '  "version": "2.0.0",'
Add-Line '  "windows": {'
Add-Line '    "options": {'
Add-Line '      "shell": {'
Add-Line ('        "executable": "{0}",' -f @('powershell.exe', 'pwsh.exe')[[bool]$core])
Add-Line '        "args": [ "-NoProfile", "-NoLogo","-ExecutionPolicy", "Bypass", "-Command" ]'
Add-Line '      }'
Add-Line '    }'
Add-Line '  },'
Add-Line '  "linux": {'
Add-Line '    "options": {'
Add-Line '      "shell": {'
Add-Line '        "executable": "/usr/bin/pwsh",'
Add-Line '        "args": [ "-NoProfile", "-Command" ]'
Add-Line '      }'
Add-Line '    }'
Add-Line '  },'
Add-Line '  "osx": {'
Add-Line '    "options": {'
Add-Line '      "shell": {'
Add-Line '        "executable": "/usr/local/bin/pwsh",'
Add-Line '        "args": [ "-NoProfile", "-Command" ]'
Add-Line '      }'
Add-Line '    }'
Add-Line '  },'
Add-Line '  "tasks": ['

# tasks.json tasks
$BuildFile2 = if ($BuildFile) { " -File '{0}'" -f $BuildFile.Replace('\', '/').Replace("'", "''") } else { '' }



foreach ($task in $all.Values)
{
    $name = $task.Name
    if ($name -match '[^\w\.\-]|^-')
    {
        continue
    }
    Add-Line '    {'
    Add-Line '      "label": "{0}",' $name
    Add-Line '      "type": "shell",'
    Add-Line '      "problemMatcher": [ "$msCompile" ],'
    if ($name -eq $dot)
    {
        Add-Line '      "group": {'
        Add-Line '        "kind": "build",'
        Add-Line '        "isDefault": true'
        Add-Line '      },'
    }
    Add-Line '      "command": "{0} -Task {1}{2}"' $InvokeBuild2 $name $BuildFile2
    Add-Line '    },'
}

# last task and ending
Add-Line '    {'
Add-Line '      "label": "?",'
Add-Line '      "type": "shell",'
Add-Line '      "problemMatcher": [],'
Add-Line '      "command": "{0} -Task ?{1}"' $InvokeBuild2 $BuildFile2
Add-Line '    }'
Add-Line '  ]'
Add-Text '}'

# save the file
if (!(Test-Path .vscode))
{
    $null = mkdir .vscode
}
elseif (Test-Path ./.vscode/tasks.json)
{
    $line1, $null = Get-Content ./.vscode/tasks.json
    if ($line1 -ne $Header)
    {
        Remove-Item ./.vscode/tasks.json -Confirm
        if (Test-Path ./.vscode/tasks.json) { return }
    }
}
Set-Content ./.vscode/tasks.json $out.ToString() -Encoding UTF8
