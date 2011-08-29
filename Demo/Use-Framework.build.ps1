
<#
.Synopsis
	Examples of Use-BuildFramework (framework).

.Description
	Points of interest:

	* If a build script changes the location it does not have to restore it.

	* Tasks v2.0.50727 and v4.0.30319 are conditional (see the If parameter).

	* Use of several frameworks simultaneously.

.Link
	Invoke-Build
	.build.ps1
#>

# Use the current framework at the script level (used by CurrentFramework).
# In order to use the current framework pass $null or '':
framework $null MSBuild

# It is fine to change the location (used for -If) and leave it changed.
Set-Location "$env:windir\Microsoft.NET\Framework"

# This task calls MSBuild 2.0 and tests its version.
task v2.0.50727 -If (Test-Path 'v2.0.50727') {
	framework Framework\v2.0.50727 MSBuild
	$version = exec { MSBuild /version /nologo }
	$version
	assert ($version -like '2.0.*')
}

# This task calls MSBuild 4.0 and tests its version.
task v4.0.30319 -If (Test-Path 'v4.0.30319') {
	framework Framework\v4.0.30319 MSBuild
	$version = exec { MSBuild /version /nologo }
	$version
	assert ($version -like '4.0.*')
}

# This task simply uses the alias set at the scope level.
task CurrentFramework {
	$version = exec { MSBuild /version /nologo }
	$version
}

# This task fails due to invalid framework specified.
task InvalidFramework {
	framework Framework\xyz MSBuild
}

# This task fails because Use-BuildFramework should not be dot-sourced.
task DoNotDotSource {
	. framework $null MSBuild
}

# The default task calls the others and checks that InvalidFramework and
# DoNotDotSource have failed. Failing tasks are referenced as @{Task=1}.
task . v2.0.50727, v4.0.30319, CurrentFramework, @{InvalidFramework=1}, @{DoNotDotSource=1}, {
	$e = error InvalidFramework
	assert ("$e" -like "Directory does not exist: '*\xyz'.")

	$e = error DoNotDotSource
	assert ("$e" -like "Use-BuildFramework should not be dot-sourced.")
}
