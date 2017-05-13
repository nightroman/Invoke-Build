
<#
.Synopsis
	Examples of Use-BuildAlias (use).

.Description
	Since v3.3.0 the command `use <version> MSBuild` uses Resolve-MSBuild.

	Points of interest:
	* If a build script changes the location it does not have to restore it.
	* Conditional tasks, see the parameters -If (...).
	* Use of several frameworks simultaneously.

.Example
	Invoke-Build * Use.test.ps1
#>

# Use the current framework at the script level (used by CurrentFramework).
use ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) MSBuild.exe

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

# VS 2017 ~ v15
if (!($ProgramFiles = ${env:ProgramFiles(x86)})) {$ProgramFiles = $env:ProgramFiles}
$VS2017 = Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017"
task Version.15.0 -If $VS2017 {
	use 15.0 MSBuild
	($version = exec { MSBuild /version /nologo })
	assert ($version -like '15.*')
	$script:LatestVersion = $version
}

task Version.Latest Version.2.0, Version.3.5, Version.4.0, Version.12.0, Version.14.0, Version.15.0, {
	use * MSBuild
	($version = exec { MSBuild /version /nologo })
	equals $version $script:LatestVersion
}

# This task simply uses the alias set at the scope level.
task CurrentFramework {
	# v6 beta
	if (!(Test-Path -LiteralPath (Get-Alias MSBuild.exe).Definition)) {
		Write-Warning 'Missing MSBuild.'
		return
	}
	($version = exec { MSBuild.exe /version /nologo })
}

# The directory path used for aliased commands should be resolved.
task ResolvedPath {
	use . MyTestAlias
	$path = (Get-Command MyTestAlias).Definition
	assert (($path -like '?:\*\MyTestAlias') -or ($path -like '\\*\MyTestAlias'))
}

# Error: missing version.
task MissingVersion {
	($r = try {<##> use 3.14 MSBuild} catch {$_})
	assert (($r | Out-String) -like '*Cannot resolve MSBuild 3.14 :*<##>*FullyQualifiedErrorId : Use-BuildAlias*')
}

# Error: invalid framework.
task InvalidFramework {
	($r = try {<##> use 'Framework\<>' MSBuild} catch {$_})
	assert (($r | Out-String) -match '(?s)^use : Cannot resolve ''Framework\\<>''.*<##>.*FullyQualifiedErrorId : Use-BuildAlias')
}

# Error: missing framework.
task MissingFramework {
	($r = try {<##> use Framework\MissingFramework MSBuild} catch {$_})
	assert (($r | Out-String) -match '(?s)^use : Cannot resolve ''Framework\\MissingFramework''.*<##>.*FullyQualifiedErrorId : Use-BuildAlias')
}

# Error: invalid directory.
task InvalidDirectory {
	($r = try {<##> use '\<>' MyScript} catch {$_})
	assert (($r | Out-String) -match '(?s)^use : Cannot resolve ''\\<>''.*<##>.*FullyQualifiedErrorId : Use-BuildAlias')
}

# Error: missing directory.
task MissingDirectory {
	($r = try {<##> use MissingDirectory MyScript} catch {$_})
	assert (($r | Out-String) -match '(?s)^use : Cannot resolve ''MissingDirectory''.*<##>.*FullyQualifiedErrorId : Use-BuildAlias')
}

# v3.2.0
task VisualStudio {
	function Test-VisualStudio($Version) {
		try {
			use VisualStudio\$Version devenv
			(Get-Alias devenv).Definition
		}
		catch {
			Write-Warning $_
		}
	}

	$versions = '9.0', '10.0', '14.0'
	$ok = 0
	foreach ($v in $versions) {
		($r = Test-VisualStudio $v)
		if ($r) {++$ok}
	}
	$ok
	assert $ok
}
