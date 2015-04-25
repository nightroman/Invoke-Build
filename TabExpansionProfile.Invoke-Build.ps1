
<#
.Synopsis
	TabExpansion2 profile for Invoke-Build completers.
	Invoke-Build - Build Automation in PowerShell
	Copyright (c) 2011-2015 Roman Kuzmin

.Description
	Requirements:
	- TabExpansion2.ps1 https://github.com/nightroman/FarNet/blob/master/PowerShellFar/TabExpansion2.ps1
	- TabExpansion2.ps1 is normally invoked in a PowerShell profile.
	- This script itself and Invoke-Build.ps1 should be in the path.

	This script is invoked on the first call of the custom TabExpansion2.
	It adds code completers for Invoke-Build.ps1 Task and File arguments.

.Link
	https://github.com/nightroman/Invoke-Build
#>

# Add completers to the option table
$TabExpansionOptions.CustomArgumentCompleters += @{

	'Invoke-Build.ps1:Task' = {
		param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

		(& $commandName ?? -File ($boundParameters['File'])).Keys -like "$wordToComplete*" |
		.{process{ New-CompletionResult $_ }}
	}

	'Invoke-Build.ps1:File' = {
		param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

		Get-ChildItem -Directory -Name "$wordToComplete*" |
		.{process{ New-CompletionResult $_ -ResultType ProviderContainer }}

		if (!($boundParameters['Task'] -eq '**')) {
			Get-ChildItem -File -Name "$wordToComplete*.ps1" |
			.{process{ New-CompletionResult $_ -ResultType Command }}
		}
	}

}
