
<#
.Synopsis
	TabExpansion2 profile for Invoke-Build.

.Description
	Use this profile with the custom TabExpansion2
	https://farnet.googlecode.com/svn/trunk/PowerShellFar/TabExpansion2.ps1

	Normally TabExpansion2.ps1 should be called in the very beginning of a
	session from a PowerShell profile. This script should be placed to the
	system path. It will be called on the first code completion.

	This completion profile adds completers for Task and File arguments of
	Build.ps1 and Invoke-Build.ps1
#>

$completeFile = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
	$r = if ($wordToComplete) {
		Get-ChildItem -Include "$wordToComplete*" -Name
	}
	else {
		Get-ChildItem -Include '*.build.ps1', '*.test.ps1' -Name
	}
	$r | .{process{ New-CompletionResult $_ }}
}

$TabExpansionOptions.CustomArgumentCompleters += @{
	'Build.ps1:Task' = {
		param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
		$file = $boundParameters['File']
		$all = Build.ps1 ?? -File $file
		$all.Keys -like "$wordToComplete*" | .{process{ New-CompletionResult $_ }}
	}
	'Invoke-Build.ps1:Task' = {
		param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
		$file = $boundParameters['File']
		$all = Invoke-Build.ps1 ?? -File $file
		$all.Keys -like "$wordToComplete*" | .{process{ New-CompletionResult $_ }}
	}
	'Build.ps1:File' = $completeFile
	'Invoke-Build.ps1:File' = $completeFile
}
