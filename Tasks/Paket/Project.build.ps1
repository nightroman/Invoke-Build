<#
.Synopsis
	Sample build script with dotnet paket and bootstrapping.

.Example
	PS> ./Project.build.ps1 Build

	This command invokes the task Build defined in this script.
	The required packages are restored on the first call.
	Then Build is invoked by the local Invoke-Build.

.Example
	PS> Invoke-Build Build

	This command is invoked by the global Invoke-Build. It may be used in
	command prompts after bootstrapping, it does not install packages.
	Note, Invoke-Build version may be different from required local.
#>

param(
	[Parameter(Position=0)]
	$Tasks
	,
	[ValidateSet('Debug', 'Release')]
	[string]$Configuration = 'Release'
)

# Direct call: ensure packages and call the local Invoke-Build

if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
	$ErrorActionPreference = 1
	$ib = "$PSScriptRoot/packages/Invoke-Build/tools/Invoke-Build.ps1"

	if (!(Test-Path -LiteralPath $ib)) {
		# restore paket and other tools
		dotnet tool restore
		if ($LASTEXITCODE) {throw "tool restore exit code: $LASTEXITCODE"}

		# ensure packages
		dotnet paket install
		if ($LASTEXITCODE) {throw "paket install exit code: $LASTEXITCODE"}
	}

	# call Invoke-Build
	return & $ib $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

# Normal call for tasks, either by local or global Invoke-Build

# Synopsis: Build project.
task Build {
	"Building $Configuration"
}

# Synopsis: Remove files.
task Clean {
	Write-Warning 'This sample removes paket.lock'
	remove .paket, packages, paket-files, paket.lock
}
