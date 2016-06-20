
<#PSScriptInfo
.VERSION 1.0.1
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) 2011-2016 Roman Kuzmin
.TAGS Invoke, Task, Invoke-Build, VSCode
.GUID 1dcf7c94-b68d-4fb7-9e2b-886889b6c42e
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Invokes the current task from VSCode by Invoke-Build.ps1

.Description
	This script invokes the current task from the build script being edited in
	Visual Studio Code. It is invoked either in VSCode or PowerShell console.

	The script is used with VSCode PowerShell extension:
	https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell

	Invoke-Build.ps1 is searched in the directory of Invoke-TaskFromVSCode.ps1
	and then in the path.

	The current task is the task at the caret line or above. If none is found
	then the default task is invoked. Currently the script should be saved
	manually before invoking.

	In order to register editor commands create or open VSCode profile:

		C:\Users\...\Documents\WindowsPowerShell\Microsoft.VSCode_profile.ps1

	and add two commands:

		Register-EditorCommand -Name IBVSCode -DisplayName 'Invoke task in VSCode' -ScriptBlock {
			param($Context)
			Invoke-TaskFromVSCode.ps1
		}

		Register-EditorCommand -Name IBConsole -DisplayName 'Invoke task in console' -SuppressOutput -ScriptBlock {
			param($Context)
			Invoke-TaskFromVSCode.ps1 -Console
		}

	These commands assume that Invoke-TaskFromVSCode.ps1 is in the path.
	If this is not the case then specify the full script path there.

	In order to show and invoke commands in VSCode, press Ctrl+Shift+P to open
	the command palette. Type the characters addi until you see the item
	"PowerShell: Show additional commands" and then press Enter.

.Parameter Console
		Tells to invoke the current task in a new PowerShell console.
#>

param(
	[Parameter()]
	[switch]$Console
)

$ErrorActionPreference = 'Stop'

$private:ib = "$(Split-Path $MyInvocation.MyCommand.Path)\Invoke-Build.ps1"
if (!(Test-Path -LiteralPath $ib)) {
	$ib = 'Invoke-Build.ps1'
}

$private:_Console = $Console
Remove-Variable Console

$private:file = $Context.CurrentFile
if (!$file) {Write-Error "There is not a current file."}

$private:path = $file.Path
if ($path -notlike '*.ps1') {Write-Error "The current file must be '*.ps1'."}

$private:task = '.'
$private:line = $Context.CursorPosition.Line
foreach($private:t in (& $ib ?? $path).Values) {
	if ($t.InvocationInfo.ScriptName -ne $path) {continue}
	if ($t.InvocationInfo.ScriptLineNumber -gt $line) {break}
	$task = $t.Name
}

if ($_Console) {
	Start-Process PowerShell.exe ("-NoExit -NoProfile -ExecutionPolicy Bypass & '{0}' '{1}' '{2}'" -f @(
		$ib.Replace("'", "''")
		$task.Replace("'", "''").Replace('"', '\"')
		$path.Replace("'", "''")
	))
}
else {
	& $ib $task $path
}
