<#
.Synopsis
	Root build script with base scripts.

.Parameter Tasks
		Specifies tasks.
.Parameter RootParam1
		Some parameter for root tasks.
#>

param(
	[ValidateScript({ "build::src/build.build.ps1", "deploy::deploy/deploy.build.ps1" })]
	$Extends
	,
	[Parameter(Position=0)]
	[string[]]$Tasks
	,
	[string]$RootParam1
)

if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
	$ErrorActionPreference=1
	return Invoke-Build -Task $Tasks -File $MyInvocation.MyCommand.Path @PSBoundParameters
}

# Synopsis: Top level task.
task root {
	"root task $RootParam1"
}

task . root
