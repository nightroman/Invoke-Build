
<#
.Synopsis
	Invokes the current task from PowerShell ISE by Invoke-Build.ps1
	Invoke-Build - Build Automation in PowerShell
	Copyright (c) 2011-2014 Roman Kuzmin

.Description
	This script invokes the current task from the build script being edited in
	PowerShell ISE. It is invoked either in ISE or in PowerShell console.
	Invoke-Build.ps1 should be in the path.

	The current task is the task at the caret line or above. If none is found
	then the default task is invoked. The script is saved if it is modified.

	If the build fails when the task is invoked in ISE and the error location
	is in the same build script then the caret is moved to the error position.

	This script may be called directly from the console pane. But it is easier
	to associate it with key shortcuts. For example, in order to invoke it by
	Ctrl+Shift+T and Ctrl+Shift+B add the following lines to the ISE profile:

		# Invoke task in ISE by Invoke-Build.ps1
		$null = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(
		'Invoke Task in ISE', {Invoke-TaskFromISE.ps1}, 'Ctrl+Shift+T')

		# Invoke task in console by Invoke-Build.ps1
		$null = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(
		'Invoke Task in Console', {Invoke-TaskFromISE.ps1 -Console}, 'Ctrl+Shift+B')

	These commands assume that Invoke-TaskFromISE.ps1 is in the path.
	If this is not the case then specify the full script path there.

	To get the ISE profile path, type $profile in the console pane:

		PS> $profile
		C:\Users\...\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

.Parameter Console
		Tells to invoke the current task in the PowerShell console.
		By default the task is invoked in ISE.

.Inputs
	None
.Outputs
	None

.Link
	https://github.com/nightroman/Invoke-Build
#>

param(
	[Parameter()]
	[switch]$Console
)

$ErrorActionPreference = 'Stop'

$private:_Console = $Console
Remove-Variable Console

$private:file = $psISE.CurrentFile
if (!$file) {Write-Error "There is not a current file."}
if ($file.IsUntitled) {Write-Error "Cannot invoke for Untitled files, please save the file."}

$private:path = $file.FullPath
if ($path -notlike '*.ps1') {Write-Error "The current file must be '*.ps1'."}

if (!$file.IsSaved) {
	$file.Save()
}

$private:task = '.'
$private:editor = $file.Editor
$private:y1 = $editor.CaretLine
$private:x1 = $editor.CaretColumn
try {
	for($private:y = $y1; $y -ge 1; --$y) {
		$editor.SetCaretPosition($y, 1)
		if (($private:text = $editor.CaretLineText) -match '^\s*task\b') {
			$null, $private:t2, $null = [System.Management.Automation.PSParser]::Tokenize($text, [ref]$null)
			if (!$t2 -or !($t2.Type -eq 'CommandArgument' -or $t2.Type -eq 'String' -or $t2.Type -eq 'Number')) {
				$x1 = 1
				$y1 = $y
				Write-Error "Cannot get the task name at line $y"
			}
			$task = $t2.Content
			break
		}
	}
}
finally {
	$editor.SetCaretPosition($y1, $x1)
}

if ($_Console) {
	$a = "-NoExit Invoke-Build.ps1 '$($task.Replace("'", "''").Replace('"', '\"'))' '$($path.Replace("'", "''"))'"
	Start-Process PowerShell.exe $a
	return
}

try {
	Invoke-Build.ps1 $task $path
}
catch {
	$ii = $_.InvocationInfo
	if ($ii.ScriptName -eq $path) {
		$editor.SetCaretPosition($ii.ScriptLineNumber, $ii.OffsetInLine)
	}
	throw
}
