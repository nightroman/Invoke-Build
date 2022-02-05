<#
.Synopsis
	Examples of Use-BuildAlias (use).

.Description
	Since v3.3.0 the command `use <version> MSBuild` uses Resolve-MSBuild.

	Points of interest:
	* If a build script changes the location it does not have to restore it.
	* Conditional tasks, see the parameters -If (...).
	* Use of several frameworks simultaneously.
#>

Import-Module .\Tools
if (Test-Unix) {return task unix}

$Is64 = [IntPtr]::Size -eq 8
$Program64 = $env:ProgramFiles
if (!($Program86 = ${env:ProgramFiles(x86)})) {$Program86 = $Program64}
$VS2017 = Test-Path "$Program86\Microsoft Visual Studio\2017"
$VS2019 = Test-Path "$Program86\Microsoft Visual Studio\2019"
$VS2022 = Test-Path "$Program64\Microsoft Visual Studio\2022"

# Use the current framework at the script level (used by CurrentFramework).
use ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) MSBuild.exe

# It is fine to change the location (used for -If) and leave it changed.
Set-Location "$env:windir\Microsoft.NET\Framework"

# These tasks calls MSBuild X.Y and test its version.

task Version.2.0 -If (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\2.0') {
	use 2.0 MSBuild.exe
	($version = exec { MSBuild.exe /version /nologo })
	assert ($version -like '2.0.*')
	$script:LatestVersion = $version

	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	if ($Is64) {
		assert ($r -like '*\Framework64\v2.0.*\MSBuild.exe')
	}
	else {
		assert ($r -like '*\Framework\v2.0.*\MSBuild.exe')
	}

	use 2.0x86 MSBuild.exe
	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	assert ($r -like '*\Framework\v2.0.*\MSBuild.exe')
}

task Version.3.5 -If (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\3.5') {
	use 3.5 MSBuild.exe
	($version = exec { MSBuild.exe /version /nologo })
	assert ($version -like '3.5.*')
	$script:LatestVersion = $version

	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	if ($Is64) {
		assert ($r -like '*\Framework64\v3.5*\MSBuild.exe')
	}
	else {
		assert ($r -like '*\Framework\v3.5*\MSBuild.exe')
	}

	use 3.5x86 MSBuild.exe
	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	assert ($r -like '*\Framework\v3.5*\MSBuild.exe')
}

task Framework.3.5 -If (Test-Path 'v3.5') {
	use Framework\v3.5 MSBuild
	($version = exec { MSBuild /version /nologo })
	assert ($version -like '3.5.*')
}

task Version.4.0 -If (Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\4.0') {
	use 4.0 MSBuild.exe
	($version = exec { MSBuild.exe /version /nologo })
	#! 4.6.81.0 after installing VS2015
	assert ($version -like '4.*')
	$script:LatestVersion = $version

	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	if ($Is64) {
		assert ($r -like '*\Framework64\v4*\MSBuild.exe')
	}
	else {
		assert ($r -like '*\Framework\v4*\MSBuild.exe')
	}

	use 4.0x86 MSBuild.exe
	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	assert ($r -like '*\Framework\v4*\MSBuild.exe')
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
	use 14.0 MSBuild.exe
	($version = exec { MSBuild.exe /version /nologo })
	assert ($version -like '14.0.*')
	$script:LatestVersion = $version

	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	if ($Is64) {
		assert ($r -like '*\14.0\bin\amd64\MSBuild.exe')
	}
	else {
		assert ($r -like '*\14.0\bin\MSBuild.exe')
	}

	use 14.0x86 MSBuild.exe
	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	assert ($r -like '*\14.0\bin\MSBuild.exe')
}

# VS 2017 ~ v15
task Version.15.0 -If $VS2017 {
	use 15.0 MSBuild.exe
	($version = exec { MSBuild.exe /version /nologo })
	assert ($version -like '15.*')
	$script:LatestVersion = $version

	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	if ($Is64) {
		assert ($r -like '*\15.0\bin\amd64\MSBuild.exe')
	}
	else {
		assert ($r -like '*\15.0\bin\MSBuild.exe')
	}

	use 15.0x86 MSBuild.exe
	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	assert ($r -like '*\15.0\bin\MSBuild.exe')
}

# VS 2019 ~ v16
task Version.16.0 -If $VS2019 {
	use 16.0 MSBuild.exe
	($version = exec { MSBuild.exe /version /nologo })
	assert ($version -like '16.*')
	$script:LatestVersion = $version

	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	if ($Is64) {
		assert ($r -like '*\Current\bin\amd64\MSBuild.exe')
	}
	else {
		assert ($r -like '*\Current\bin\MSBuild.exe')
	}

	use 16.0x86 MSBuild.exe
	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	assert ($r -like '*\Current\bin\MSBuild.exe')
}

# VS 2022 ~ v17
task Version.17.0 -If $VS2022 {
	use 17.0 MSBuild.exe
	($version = exec { MSBuild.exe /version /nologo })
	assert ($version -like '17.*')
	$script:LatestVersion = $version

	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	if ($Is64) {
		assert ($r -like '*\Current\bin\amd64\MSBuild.exe')
	}
	else {
		assert ($r -like '*\Current\bin\MSBuild.exe')
	}

	use 17.0x86 MSBuild.exe
	($r = Test-MSBuild (Get-Alias MSBuild.exe))
	assert ($r -like '*\Current\bin\MSBuild.exe')
}

task Version.Latest Version.2.0, Version.3.5, Version.4.0, Version.12.0, Version.14.0, Version.15.0, Version.16.0, Version.17.0, {
	use * MSBuild.exe
	($r1 = Test-MSBuild (Get-Alias MSBuild.exe))
	($version = exec { MSBuild.exe /version /nologo })
	equals $version $script:LatestVersion

	use *x86 MSBuild.exe
	($r2 = Test-MSBuild (Get-Alias MSBuild.exe))
	if ($Is64) {
		assert ($r1 -ne $r2)
	}
	else {
		equals $r1 $r2
	}
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
	($r = try {use 3.14 MSBuild} catch {$_})
	equals "$r" 'Cannot resolve MSBuild 3.14 : The specified version is not found.'
	equals $r.InvocationInfo.ScriptName $BuildFile
	equals $r.FullyQualifiedErrorId Use-BuildAlias
}

# Error: invalid framework.
task InvalidFramework {
	($r = try {use 'Framework\<>' MSBuild} catch {$_})
	equals "$r" "Cannot resolve 'Framework\<>'."
	equals $r.InvocationInfo.ScriptName $BuildFile
	equals $r.FullyQualifiedErrorId Use-BuildAlias
}

# Error: missing framework.
task MissingFramework {
	($r = try {use Framework\MissingFramework MSBuild} catch {$_})
	equals "$r" "Cannot resolve 'Framework\MissingFramework'."
	equals $r.InvocationInfo.ScriptName $BuildFile
	equals $r.FullyQualifiedErrorId Use-BuildAlias
}

# Error: invalid directory.
task InvalidDirectory {
	($r = try {use '\<>' MyScript} catch {$_})
	equals "$r" "Cannot resolve '\<>'."
	equals $r.InvocationInfo.ScriptName $BuildFile
	equals $r.FullyQualifiedErrorId Use-BuildAlias
}

# Error: missing directory.
task MissingDirectory {
	($r = try {use MissingDirectory MyScript} catch {$_})
	equals "$r" "Cannot resolve 'MissingDirectory'."
	equals $r.InvocationInfo.ScriptName $BuildFile
	equals $r.FullyQualifiedErrorId Use-BuildAlias
}
