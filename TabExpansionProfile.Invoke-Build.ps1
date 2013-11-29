
<#
.Synopsis
	TabExpansion2 profile for Invoke-Build.

.Description
	Use this profile with the custom TabExpansion2
	https://farnet.googlecode.com/svn/trunk/PowerShellFar/TabExpansion2.ps1

	Normally TabExpansion2.ps1 should be called in the very beginning of a
	session from a PowerShell profile. This script should be placed to the
	system path. It will be called on the first code completion.

	This script adds completers for Task and File arguments of Build.ps1 and
	Invoke-Build.ps1
#>

# Common completer for File of Build.ps1 and Invoke-Build.ps1.
$completeFile = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
	Get-ChildItem -Directory -Name "$wordToComplete*"
	if (!($boundParameters['Task'] -eq '**')) {
		Get-ChildItem -File -Name "$wordToComplete*.ps1"
	}
}

# Add completers to the option table
$TabExpansionOptions.CustomArgumentCompleters += @{
	'Build.ps1:Task' = {
		param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
		(Build.ps1 ?? -File ($boundParameters['File'])).Keys -like "$wordToComplete*"
	}
	'Invoke-Build.ps1:Task' = {
		param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
		(Invoke-Build.ps1 ?? -File ($boundParameters['File'])).Keys -like "$wordToComplete*"
	}
	'Build.ps1:File' = $completeFile
	'Invoke-Build.ps1:File' = $completeFile
}
