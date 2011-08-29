
<#
.Synopsis
	The build script of the project and also a master script example.

.Description
	There is nothing to compile in this project. But Invoke-Build is suitable
	for automating all operations on project files, not just classic builds.

	This script is an example of master build scripts. In contrast to classic
	scripts master build scripts are invoked directly, not by Invoke-Build.

	The advantage of master scripts is that they are much easier to call. This
	is especially true when they have a lot of parameters. The price is quite
	low, just a couple of dot-sourced calls in the beginning and the end:

		. Invoke-Build $BuildTask
		. Start-Build

	This script is used in the development and included into the published
	archive only as an example. It may not work in some environments, for
	example it requires 7z.exe and Invoke-Build.ps1 in the system path.

.Example
	># As far as it is a master script, it is called directly:

	.\Build.ps1 ?          # Show tasks and their relations
	.\Build.ps1 zip        # Invoke the Zip and related tasks
	.\Build.ps1 . -WhatIf  # Show what if the . task is called

.Link
	Invoke-Build
#>

# For a simple script like this one command without param() would be enough:
# . Invoke-Build $args
# The script still uses param(...) just in order to show how it works.
param
(
	$BuildTask,
	[switch]$WhatIf
)

# Master script step 1: Dot-source Invoke-Build with tasks and options.
# Then scripts do what they want but the goal is to create a few tasks.
. Invoke-Build $BuildTask -WhatIf:$WhatIf

# Invoke-Build does not change system settings, scripts do:
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# Required tools (to fail if missing):
Set-Alias 7z @(Get-Command 7z)[0].Definition

# Warns about not empty git status if .git exists.
# NOTE: The task is not invoked if .git is missing.
task Git-Status -If (Test-Path .git) {
	$status = exec { git status -s }
	if ($status) {
		Write-Warning "Git status: $($status -join ', ')"
	}
}

# Copy Invoke-Build.ps1 from its working location to the project home.
# Assert: fail if the project file is newer, it is not supposed to be.
task Update-Script {
	$target = Get-Item Invoke-Build.ps1 -ErrorAction 0
	$source = Get-Item (Get-Command Invoke-Build.ps1).Definition
	assert (!$target -or ($target.LastWriteTime -le $source.LastWriteTime))
	Copy-Item $source.FullName .
}

# Test Demo scripts
task Test {
	Invoke-Build . Demo\.build.ps1
}

# Make the zip using the latest script and its version
task Zip Update-Script, Git-Status, {
	exec { & 7z a Invoke-Build.$(Get-BuildVersion).zip * '-x!.git' }
}

# The default task is a super test. It tests all and clean.
task . Test, Zip, {
	Remove-Item Invoke-Build.$(Get-BuildVersion).zip
}

# Master script step 2: Invoke build tasks. This is often the last command but
# this is not a requirement, for example scripts can do some post-build jobs.
. Start-Build
