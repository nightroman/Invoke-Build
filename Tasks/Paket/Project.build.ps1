
<#
.Synopsis
	Sample build script with automatic bootstrapping.

.Example
	PS> ./Project.build.ps1 Build

	This command invokes the task Build defined in this script.
	The required packages are downloaded on the first call.
	Then the task is invoked by local Invoke-Build.

.Example
	PS> Invoke-Build Build

	This also invokes the task Build defined in this script. But:
	- It is invoked by global Invoke-Build.
	- It does not install packages.
#>

param(
	[Parameter(Position=0)]
	$Tasks,
	$Param1 = 'Default1'
)

# Direct call: ensure packages and call the local Invoke-Build

if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
	$ErrorActionPreference = 'Stop'
	$ib = "$PSScriptRoot/packages/Invoke-Build/tools/Invoke-Build.ps1"

	# install packages
	if (!(Test-Path -LiteralPath $ib)) {
		& $PSScriptRoot/.paket/paket.exe install
		if ($LASTEXITCODE) {throw "paket exit code: $LASTEXITCODE"}
	}

	# call Invoke-Build
	& $ib -Task $Tasks -File $MyInvocation.MyCommand.Path @PSBoundParameters
	return
}

# Normal call for tasks, either by local or global Invoke-Build

# Synopsis: Build something.
task Build {
	"Building $Param1..."
}

# Synopsis: Install packages explicitly.
task Init {
	exec { ./.paket/paket.exe install }
}

# Synopsis: Remove temporary stuff.
task Clean {
	Remove-Item packages, paket-files, paket.lock -Force -Recurse
}
