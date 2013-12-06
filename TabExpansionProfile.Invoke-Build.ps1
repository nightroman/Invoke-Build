
<#
.Synopsis
	TabExpansion2 profile for Invoke-Build.

.Description
	This script should be in the path. It is invoked on the first call of the
	custom TabExpansion2. It adds code completers to the global option table.
	https://farnet.googlecode.com/svn/trunk/PowerShellFar/TabExpansion2.ps1

	This profile adds completers for Task and File arguments of Build.ps1 and
	Invoke-Build.ps1
#>

# Common completer for Task of Build.ps1 and Invoke-Build.ps1.
$completeTask = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

	(& $commandName ?? -File ($boundParameters['File'])).Keys -like "$wordToComplete*" |
	.{process{ New-CompletionResult $_ }}
}

# Common completer for File of Build.ps1 and Invoke-Build.ps1.
$completeFile = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

	Get-ChildItem -Directory -Name "$wordToComplete*" |
	.{process{ New-CompletionResult $_ -ResultType ProviderContainer }}

	if (!($boundParameters['Task'] -eq '**')) {
		Get-ChildItem -File -Name "$wordToComplete*.ps1" |
		.{process{ New-CompletionResult $_ -ResultType Command }}
	}
}

# Add completers to the option table
$TabExpansionOptions.CustomArgumentCompleters += @{
	'Build.ps1:Task' = $completeTask
	'Build.ps1:File' = $completeFile
	'Invoke-Build.ps1:Task' = $completeTask
	'Invoke-Build.ps1:File' = $completeFile
}
