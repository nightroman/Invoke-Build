
<#PSScriptInfo
.VERSION 1.0.4
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) Roman Kuzmin
.TAGS Invoke, Task, Invoke-Build, VSCode
.GUID 1dcf7c94-b68d-4fb7-9e2b-886889b6c42e
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Invokes the current Invoke-Build task from VSCode

.Description
	This script invokes the current task from the build script in VSCode.
	It is invoked in the session or in an external PowerShell console.
	The script requires the VSCode PowerShell extension.

	The current task is the task at the caret or above. If none is found then
	the default task is invoked. Currently the script should be saved manually.

	Invoke the script directly from the integrated console or register it for
	PowerShell.ShowAdditionalCommands. Create or open the VSCode profile:

		C:\Users\...\Documents\WindowsPowerShell\Microsoft.VSCode_profile.ps1

	and add commands:

		Register-EditorCommand -Name IB1 -DisplayName 'Invoke task' -ScriptBlock {
			Invoke-TaskFromVSCode.ps1
		}

		Register-EditorCommand -Name IB2 -DisplayName 'Invoke task in console' -SuppressOutput -ScriptBlock {
			Invoke-TaskFromVSCode.ps1 -Console
		}

	Specify the full path if Invoke-TaskFromVSCode.ps1 is not in the path.
	You can add a keyboard shortcut for PowerShell.ShowAdditionalCommands.

.Parameter Console
		Tells to invoke the task in an external PowerShell console.
#>

param(
	[Parameter()]
	[switch]$Console
)

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 'Stop'

$private:file = $null
try {
	$private:context = $psEditor.GetEditorContext()
	$file = $context.CurrentFile
}
catch {}
if (!$file) {throw 'Cannot get the current file.'}

$private:_Console = $Console
Remove-Variable Console

$private:path = $file.Path
if ($path -notlike '*.ps1') {throw "The current file must be '*.ps1'."}

$private:task = '.'
$private:line = $context.CursorPosition.Line
foreach($private:t in (Invoke-Build ?? $path).Values) {
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
