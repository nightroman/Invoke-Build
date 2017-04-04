
<#PSScriptInfo
.VERSION 1.1.0
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) Roman Kuzmin
.TAGS Invoke-Build, MSBuild
.GUID 53c01926-4fc5-4cbd-aa46-32e415b2373b
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Finds the specified or latest MSBuild.

.Description
	The script finds the path to the specified or latest version of MSBuild.
	It is designed to work for MSBuild 2.0-15.0 and support future versions.

	For MSBuild 15.0+ the command uses VSSetup module from PSGallery.
	If it is not installed then some default locations are checked.
	Thus, VSSetup module is required for not default installations.

	For MSBuild 2.0-14.0 the information is taken from the registry.

.Parameter Version
		Specifies the required MSBuild version. If it is omitted, empty, or *
		then the command finds and returns the latest installed version path.

.Outputs
	The full path to MSBuild.exe

.Example
	Resolve-MSBuild 15.0
	Gets location of MSBuild installed with Visual Studio 2017.

.Link
	https://www.powershellgallery.com/packages/VSSetup
#>

[CmdletBinding()]
param(
	[string]$Version
)

function Get-MSBuild15VSSetup {
	if (Get-Module VSSetup -ListAvailable) {
		Import-Module VSSetup
		if ($vsInstances = Get-VSSetupInstance) {
			$vs = @($vsInstances | Select-VSSetupInstance -Version 15.0 -Require Microsoft.Component.MSBuild)
			if ($vs) {
				return Join-Path ($vs[0].InstallationPath) MSBuild\15.0\Bin\MSBuild.exe
			}
			$vs = @($vsInstances | Select-VSSetupInstance -Version 15.0 -Product Microsoft.VisualStudio.Product.BuildTools)
			if ($vs) {
				return Join-Path ($vs[0].InstallationPath) MSBuild\15.0\Bin\MSBuild.exe
			}
		}
	}
}

function Get-MSBuild15Guess {
	if (!($root = ${env:ProgramFiles(x86)})) {$root = $env:ProgramFiles}
	if (Test-Path -LiteralPath "$root\Microsoft Visual Studio\2017") {
		$rp = @(Resolve-Path "$root\Microsoft Visual Studio\2017\*\MSBuild\15.0\Bin\MSBuild.exe" -ErrorAction 0)
		if ($rp) {
			$rp[-1].ProviderPath
		}
	}
}

function Get-MSBuild15 {
	if ($path = Get-MSBuild15VSSetup) {
		$path
	}
	else {
		Get-MSBuild15Guess
	}
}

function Get-MSBuildOldLatest {
	$rp = @(Get-ChildItem HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions | Sort-Object {[Version]$_.PSChildName})
	if ($rp) {
		Join-Path ($rp[-1].GetValue('MSBuildToolsPath')) MSBuild.exe
	}
}

function Get-MSBuildOldVersion($Version) {
	$rp = [Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$Version", 'MSBuildToolsPath', '')
	if ($rp) {
		Join-Path $rp MSBuild.exe
	}
}

$ErrorActionPreference = 1
try {
	$v15 = [Version]'15.0'
	$vMax = [Version]'9999.0'
	if (!$Version) {$Version = '*'}
	$vRequired = if ($Version -eq '*') {$vMax} else {[Version]$Version}

	if ($vRequired -eq $v15) {
		if ($path = Get-MSBuild15) {
			return $path
		}
	}
	elseif ($vRequired -lt $v15) {
		if ($path = Get-MSBuildOldVersion $Version) {
			return $path
		}
	}
	elseif ($vRequired -eq $vMax) {
		if ($path = Get-MSBuild15) {
			return $path
		}
		if ($path = Get-MSBuildOldLatest) {
			return $path
		}
	}

	throw 'The specified version is not found.'
}
catch {
	Write-Error "Cannot resolve MSBuild $Version : $_"
}
