
<#
.Synopsis
	The build script of the Invoke-Build project.

.Description
	There is nothing to compile in this project. But Invoke-Build is suitable
	for automating all operations on project files, not just classic builds.

	This script is used in the development and included into the published
	archive only as an example. It may not work in some environments, for
	example it requires 7z.exe and Invoke-Build.ps1 in the system path.
#>

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

# Copy Invoke-Build.ps1 from its working location to the project home
task Update-Script {
	Copy-Item (Get-Command Invoke-Build.ps1).Definition .
}

# Take $script:Version string from Invoke-Build.ps1
task Version {
	$text = [System.IO.File]::ReadAllText("$BuildRoot\Invoke-Build.ps1")
	assert ($text -match '\s*Invoke-Build\s+(v\d+\.\d+\.\d+(\.\w+)?)\s+')
	$script:Version = $matches[1]
}

# Test Demo scripts
task Test {
	Invoke-Build . Demo\.build.ps1
}

# Make the zip using the latest script and its version string
task Zip Update-Script, Version, Git-Status, {
	exec { & 7z a Invoke-Build.$script:Version.zip * '-x!.git' }
}

# The default task is a super test. It tests all and clean.
task . Test, Zip, {
	Remove-Item Invoke-Build.$script:Version.zip
}
