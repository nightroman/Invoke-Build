<#PSScriptInfo
.VERSION 1.0.7
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) Roman Kuzmin
.TAGS Invoke-Build, Task, VSCode
.GUID 1dcf7c94-b68d-4fb7-9e2b-886889b6c42e
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Invokes the current Invoke-Build task from VSCode

.Description
	This script invokes the current task from the build script in VSCode.

	Requires:
	- Invoke-Build
	- VSCode PowerShell

	How to use:
	https://github.com/nightroman/Invoke-Build/wiki/Invoke-Task-from-VSCode

.Parameter Console
		Tells to invoke the task in an external console.

.Link
	https://github.com/nightroman/Invoke-Build/wiki/Invoke-Task-from-VSCode
#>

param(
	[Parameter()]
	[switch]$Console
)

$ErrorActionPreference = 1
try {

$private:file = $null
try {
	$private:context = $psEditor.GetEditorContext()
	$file = $context.CurrentFile
}
catch {}
if (!$file) {throw 'Cannot get the current file.'}

# save if modified, #118
if ($psEditor.EditorServicesVersion -ge [version]'1.6') {
	$file.Save()
}

$private:_Console = $Console
Remove-Variable Console

$private:path = $file.Path
if ($path -notlike '*.ps1') {throw "The current file must be '*.ps1'."}

$private:task = '.'
$private:line = $context.CursorPosition.Line
foreach($private:t in (Invoke-Build ?? $path).get_Values()) {
	if ($t.InvocationInfo.ScriptName -ne $path) {continue}
	if ($t.InvocationInfo.ScriptLineNumber -gt $line) {break}
	$task = $t.Name
}

if ($_Console) {
	$command = "Invoke-Build '$($task.Replace("'", "''"))' '$($path.Replace("'", "''"))'"
	$encoded = [Convert]::ToBase64String(([System.Text.Encoding]::Unicode.GetBytes($command)))
	Start-Process powershell.exe "-NoExit -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded"
}
else {
	Invoke-Build $task $path
}

} catch {if ($_.InvocationInfo.ScriptName -like '*Invoke-TaskFromVSCode.ps1') {$PSCmdlet.ThrowTerminatingError($_)} throw}
