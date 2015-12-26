
<#
.Synopsis
	Examples of Use-BuildAlias (use).

.Description
	Points of interest:

	* If a build script changes the location it does not have to restore it.
	* Tasks v2.0.50727 and v4.0.30319 are conditional (see the If parameter).
	* Use of several frameworks simultaneously.

.Example
	Invoke-Build * Use.test.ps1
#>

. .\Shared.ps1

# Use the current framework at the script level (used by CurrentFramework).
use ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) MSBuild

# It is fine to change the location (used for -If) and leave it changed.
Set-Location "$env:windir\Microsoft.NET\Framework"

# These tasks calls MSBuild X.Y and test its version.

task Version.2.0 -If (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\2.0') {
	use 2.0 MSBuild
	($version = exec { MSBuild /version /nologo })
	assert ($version -like '2.0.*')
	$script:LatestVersion = $version
}

task Framework.2.0.50727 -If (Test-Path 'v2.0.50727') {
	use Framework\v2.0.50727 MSBuild
	($version = exec { MSBuild /version /nologo })
	assert ($version -like '2.0.*')
}

task Version.3.5 -If (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\3.5') {
	use 3.5 MSBuild
	($version = exec { MSBuild /version /nologo })
	assert ($version -like '3.5.*')
	$script:LatestVersion = $version
}

task Framework.3.5 -If (Test-Path 'v3.5') {
	use Framework\v3.5 MSBuild
	($version = exec { MSBuild /version /nologo })
	assert ($version -like '3.5.*')
}

task Version.4.0 -If (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\4.0') {
	use 4.0 MSBuild
	($version = exec { MSBuild /version /nologo })
	#! 4.6.81.0 after installing VS2015
	assert ($version -like '4.*')
	$script:LatestVersion = $version
}

task Framework.4.0.30319 -If (Test-Path 'v4.0.30319') {
	use Framework\v4.0.30319 MSBuild
	($version = exec { MSBuild /version /nologo })
	#! 4.6.81.0 after installing VS2015
	assert ($version -like '4.*')
}

# VS 2013 ~ v12
task Version.12.0 -If (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\12.0') {
	use 12.0 MSBuild
	($version = exec { MSBuild /version /nologo })
	assert ($version -like '12.0.*')
	$script:LatestVersion = $version
}

# VS 2015 ~ v14
task Version.14.0 -If (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\14.0') {
	use 14.0 MSBuild
	($version = exec { MSBuild /version /nologo })
	assert ($version -like '14.0.*')
	$script:LatestVersion = $version
}

task Version.Latest Version.2.0, Version.3.5, Version.4.0, Version.12.0, Version.14.0, {
	use * MSBuild
	($version = exec { MSBuild /version /nologo })
	equals $version $script:LatestVersion
}

# This task simply uses the alias set at the scope level.
task CurrentFramework {
	($version = exec { MSBuild /version /nologo })
}

# The directory path used for aliased commands should be resolved.
task ResolvedPath {
	use . MyTestAlias
	$path = (Get-Command MyTestAlias).Definition
	assert (($path -like '?:\*\MyTestAlias') -or ($path -like '\\*\MyTestAlias'))
}

# Error: missing version.
task MissingVersion {
	use 3.14 MSBuild
}

# Error: invalid framework.
task InvalidFramework {
	use 'Framework\<>' MSBuild
}

# Error: missing framework.
task MissingFramework {
	use Framework\MissingFramework MSBuild
}

# Error: invalid directory.
task InvalidDirectory {
	use '\<>' MyScript
}

# Error: missing directory.
task MissingDirectory {
	use MissingDirectory MyScript
}

# The default task calls the others and checks that InvalidFramework and
# DoNotDotSource have failed. Failing tasks are referenced as safe.
task . `
(job MissingVersion -Safe),
(job MissingFramework -Safe),
(job InvalidFramework -Safe),
(job MissingDirectory -Safe),
(job InvalidDirectory -Safe),
{
	Test-Error MissingVersion   "Cannot resolve '3.14'.*"
	Test-Error InvalidFramework "Cannot resolve 'Framework\<>'.*"
	Test-Error MissingFramework "Cannot resolve 'Framework\MissingFramework'.*"
	Test-Error InvalidDirectory "Cannot resolve '\<>'.*"
	Test-Error MissingDirectory "Cannot resolve 'MissingDirectory'.*"
}
