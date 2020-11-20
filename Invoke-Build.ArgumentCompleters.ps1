<#PSScriptInfo
.VERSION 1.0.4
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) Roman Kuzmin
.GUID 78b68f80-80c5-4cc1-9ded-e2ae165a9cbd
.TAGS Invoke-Build, TabExpansion2, Register-ArgumentCompleter
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Argument completers for Invoke-Build parameters.

.Description
	The script registers Invoke-Build completers for parameters Task and File.

	Completers can be used with:

	* PowerShell v5 native Register-ArgumentCompleter
	Simply invoke Invoke-Build.ArgumentCompleters.ps1, e.g. in a profile.

	* TabExpansion2.ps1 https://www.powershellgallery.com/packages/TabExpansion2
	Put Invoke-Build.ArgumentCompleters.ps1 to the path in order to be loaded
	automatically on the first completion. Or invoke after TabExpansion2.ps1,
	e.g. in a profile.
#>

Register-ArgumentCompleter -CommandName Invoke-Build.ps1 -ParameterName Task -ScriptBlock {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

	(Invoke-Build -Task ?? -File ($boundParameters['File'])).get_Keys() -like "$wordToComplete*" | .{process{
		New-Object System.Management.Automation.CompletionResult $_, $_, 'ParameterValue', $_
	}}
}

Register-ArgumentCompleter -CommandName Invoke-Build.ps1 -ParameterName File -ScriptBlock {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

	Get-ChildItem -Directory -Name "$wordToComplete*" | .{process{
		New-Object System.Management.Automation.CompletionResult $_, $_, 'ProviderContainer', $_
	}}

	if (!($boundParameters['Task'] -eq '**')) {
		Get-ChildItem -File -Name "$wordToComplete*.ps1" | .{process{
			New-Object System.Management.Automation.CompletionResult $_, $_, 'Command', $_
		}}
	}
}
