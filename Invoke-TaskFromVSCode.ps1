<#PSScriptInfo
.VERSION 1.1.0
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) Roman Kuzmin
.TAGS Invoke-Build, Task, VSCode
.GUID 1dcf7c94-b68d-4fb7-9e2b-886889b6c42e
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Invokes the current Invoke-Build task from VSCode.

.Description
	It invokes the current task from the current build script opened in VSCode.

	Requires:
	- Invoke-Build
	- VSCode PowerShell

	How to use:
	https://github.com/nightroman/Invoke-Build/blob/main/Docs/Invoke-Task-from-VSCode.md

.Parameter Console
		Tells to invoke the task in an external console.

.Link
	https://github.com/nightroman/Invoke-Build/blob/main/Docs/Invoke-Task-from-VSCode.md
#>

[CmdletBinding()]
param(
	[switch]$Console
)

$ErrorActionPreference=1; trap {throw $_}

$private:file = $null
try {
	$private:context = $psEditor.GetEditorContext()
	$file = $context.CurrentFile
}
catch {}

if (!$file) {
	return Write-Warning "No current file."
}

# save if modified, #118
$file.Save()

$private:path = $file.Path
if ($path -notlike '*.ps1') {
	return Write-Warning "No current .ps1 file."
}

$private:_Console = $Console
Remove-Variable Console

$goodTasksDic = Invoke-Build ?? $path -Result:Result
$goodTasks = $goodTasksDic.get_Values()
$dupeTasks = $Result.Redefined
$line = $context.CursorPosition.Line

function __find_caret_task($Tasks, $Path, $Line) {
	$bestTaskName = ''
	$bestLineNumber = -1
	foreach($task in $Tasks) {
		$ii = $task.InvocationInfo

		# skip different file
		if ($ii.ScriptName -ne $Path) {
			continue
		}

		# stop on any task below the caret
		if ($ii.ScriptLineNumber -gt $Line) {
			break
		}

		# keep the best
		$bestTaskName = $task.Name
		$bestLineNumber = $ii.ScriptLineNumber
	}
	[pscustomobject]@{Name = $bestTaskName; LineNumber = $bestLineNumber}
}

$goodTask = __find_caret_task $goodTasks $path $line
$dupeTask = __find_caret_task $dupeTasks $path $line

# no dupe or good task?
if (!$dupeTask.Name -and !$goodTask.Name) {
	return Write-Warning "No current task."
}

# dupe task and no good task better than dupe?
if ($dupeTask.Name -and $goodTask.LineNumber -lt $dupeTask.LineNumber) {
	$ii = $goodTasksDic[$dupeTask.Name].InvocationInfo
	Write-Warning "Invoking redefined task at $($ii.ScriptName):$($ii.scriptLineNumber)"
	$goodTask = $dupeTask
}

if ($_Console) {
	$command = "Invoke-Build '$($goodTask.Name.Replace("'", "''"))' '$($path.Replace("'", "''"))'"
	$encoded = [Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($command)))
	Start-Process powershell.exe "-NoExit -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
}
else {
	Invoke-Build $goodTask.Name $path
}
