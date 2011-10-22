
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

.Link
	Invoke-Build
	.build.ps1
#>

# Use the current framework at the script level (used by CurrentFramework).
# In order to use the current framework pass $null or '':
use $null MSBuild

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
	$e = error MissingFramework
	assert (($e | Out-String) -like "Use-BuildAlias : Directory does not exist: '*\Microsoft.NET\Framework\MissingFramework'.* use <<<< *")

	$e = error InvalidFramework
	assert (($e | Out-String) -like "Use-BuildAlias : Directory does not exist: '*\Microsoft.NET\Framework\<>'.* use <<<< *")

	$e = error MissingDirectory
	assert (($e | Out-String) -like "Use-BuildAlias : Directory does not exist: '*\MissingDirectory'.* use <<<< *")
	assert ($e.TargetObject -eq 'MissingDirectory')

	$e = error InvalidDirectory
	assert (($e | Out-String) -like "Use-BuildAlias : * use <<<< *")
	assert ($e.TargetObject -eq '\<>')
}
