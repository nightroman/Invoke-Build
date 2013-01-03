
<#
.Synopsis
	Examples of Use-BuildAlias (use).

.Description
	Points of interest:

	* If a build script changes the location it does not have to restore it.
	* Tasks v2.0.50727 and v4.0.30319 are conditional (see the If parameter).
	* Use of several frameworks simultaneously.

.Example
	Invoke-Build . Use.build.ps1
#>

. .\Shared.ps1

# Use the current framework at the script level (used by CurrentFramework).
use ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) MSBuild

# It is fine to change the location (used for -If) and leave it changed.
Set-Location "$env:windir\Microsoft.NET\Framework"

# This task calls MSBuild 2.0 and tests its version.
task v2.0.50727 -If (Test-Path 'v2.0.50727') {
	use Framework\v2.0.50727 MSBuild
	$version = exec { MSBuild /version /nologo }
	$version
	assert ($version -like '2.0.*')
}

# This task calls MSBuild 4.0 and tests its version.
task v4.0.30319 -If (Test-Path 'v4.0.30319') {
	use Framework\v4.0.30319 MSBuild
	$version = exec { MSBuild /version /nologo }
	$version
	assert ($version -like '4.0.*')
}

# This task simply uses the alias set at the scope level.
task CurrentFramework {
	$version = exec { MSBuild /version /nologo }
	$version
}

# The directory path used for aliased commands should be resolved.
task ResolvedPath {
	use . MyTestAlias
	$path = (Get-Command MyTestAlias).Definition
	assert (($path -like '?:\*\MyTestAlias') -or ($path -like '\\*\MyTestAlias'))
}

# Error: missing framework.
task MissingFramework {
	use Framework\MissingFramework MSBuild
}

# Error: invalid framework.
task InvalidFramework {
	use 'Framework\<>' MSBuild
}

# Error: missing directory.
task MissingDirectory {
	use MissingDirectory MyScript
}

# Error: invalid directory.
task InvalidDirectory {
	use '\<>' MyScript
}

# The default task calls the others and checks that InvalidFramework and
# DoNotDotSource have failed. Failing tasks are referenced as @{Task=1}.
task . `
v2.0.50727,
v4.0.30319,
CurrentFramework,
ResolvedPath,
@{MissingFramework=1},
@{InvalidFramework=1},
@{MissingDirectory=1},
@{InvalidDirectory=1},
{
	Test-Error MissingFramework "Missing directory '*\Microsoft.NET\Framework\MissingFramework'.*Framework\MissingFramework MSBuild*"
	Test-Error InvalidFramework "Missing directory '*\Microsoft.NET\Framework\<>'.*'Framework\<>'*"
	Test-Error MissingDirectory "Missing directory '*\MissingDirectory'.*MissingDirectory MyScript*"
	Test-Error InvalidDirectory "*'\<>' MyScript*"
}
