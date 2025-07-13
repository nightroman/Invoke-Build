<#
.Synopsis
	Directly invocable build script with Invoke-Build bootstrapping.

.Example
	PS> ./Project.build.ps1 Build

	This command invokes the task Build defined in this script.
	If Invoke-Build is not available, its module is installed.
	Then Invoke-Build is called.

.Example
	PS> Invoke-Build Build

	This command may be used when Invoke-Build is available.
#>

param(
	[Parameter(Position=0)]
	$Tasks
	,
	[ValidateSet('Debug', 'Release')]
	[string]$Configuration = 'Release'
)

# bootstrap
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
	$ErrorActionPreference = 1
	if (!(Get-Command Invoke-Build -ErrorAction 0)) {
		Write-Host InvokeBuild installing...
		Install-Module InvokeBuild -Scope CurrentUser -Force
		Import-Module InvokeBuild
	}
	return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

# Synopsis: Build project.
task Build {
	"Building $Configuration"
}
