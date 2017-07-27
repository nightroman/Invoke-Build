
<#PSScriptInfo
.VERSION 1.2.0
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

	MSBuild 15.0+ resolution precedence: Enterprise, Professional, Community,
	another product. If this is not suitable then use VSSetup module directly.

	For MSBuild 2.0-14.0 the information is taken from the registry.

.Parameter Version
		Specifies the required MSBuild version. If it is omitted, empty, or *
		then the command finds and returns the latest installed version path.
		The optional suffix x86 tells to use 32-bit MSBuild.

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

function Get-MSBuild15Path($Bitness) {
	if ([System.IntPtr]::Size -eq 4 -or $Bitness -eq 'x86') {
		'MSBuild\15.0\Bin\MSBuild.exe'
	}
	else {
		'MSBuild\15.0\Bin\amd64\MSBuild.exe'
	}
}

function Get-MSBuild15VSSetup($Bitness) {
	if (!(Get-Module VSSetup -ListAvailable)) {return}
	Import-Module VSSetup

	$vs = Get-VSSetupInstance | Select-VSSetupInstance -Version 15.0 -Require Microsoft.Component.MSBuild -Product *
	if (!$vs) {return}

	$vs = if ($r = $vs | Select-VSSetupInstance -Product Microsoft.VisualStudio.Product.Enterprise) {$r}
	elseif ($r = $vs | Select-VSSetupInstance -Product Microsoft.VisualStudio.Product.Professional) {$r}
	elseif ($r = $vs | Select-VSSetupInstance -Product Microsoft.VisualStudio.Product.Community) {$r}
	else {$vs}

	if ($vs) {
		Join-Path @($vs)[0].InstallationPath (Get-MSBuild15Path $Bitness)
	}
}

function Get-MSBuild15Guess($Bitness) {
	if (!($root = ${env:ProgramFiles(x86)})) {$root = $env:ProgramFiles}
	if (!(Test-Path -LiteralPath "$root\Microsoft Visual Studio\2017")) {return}

	$paths = @(
		foreach($_ in Resolve-Path "$root\Microsoft Visual Studio\2017\*\$(Get-MSBuild15Path $Bitness)" -ErrorAction 0) {
			$_.ProviderPath
		}
	)

	if ($paths) {
		if ($r = $paths -like '*\Enterprise\*') {return $r}
		if ($r = $paths -like '*\Professional\*') {return $r}
		if ($r = $paths -like '*\Community\*') {return $r}
		$paths[0]
	}
}

function Get-MSBuild15($Bitness) {
	if ($path = Get-MSBuild15VSSetup $Bitness) {
		$path
	}
	else {
		Get-MSBuild15Guess $Bitness
	}
}

function Get-MSBuildOldVersion($Version, $Bitness) {
	if ([System.IntPtr]::Size -eq 8 -and $Bitness -eq 'x86') {
		$key = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\MSBuild\ToolsVersions\$Version"
	}
	else {
		$key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$Version"
	}
	$rp = [Microsoft.Win32.Registry]::GetValue($key, 'MSBuildToolsPath', '')
	if ($rp) {
		Join-Path $rp MSBuild.exe
	}
}

function Get-MSBuildOldLatest($Bitness) {
	$rp = @(Get-ChildItem HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions | Sort-Object {[Version]$_.PSChildName})
	if ($rp) {
		Get-MSBuildOldVersion $rp[-1].PSChildName $Bitness
	}
}

$ErrorActionPreference = 1
try {
	if ($Version -match '^(.*?)(x86)$') {
		$Version = $matches[1]
		$Bitness = $matches[2]
	}
	else {
		$Bitness = ''
	}

	$v15 = [Version]'15.0'
	$vMax = [Version]'9999.0'
	if (!$Version) {$Version = '*'}
	$vRequired = if ($Version -eq '*') {$vMax} else {[Version]$Version}

	if ($vRequired -eq $v15) {
		if ($path = Get-MSBuild15 $Bitness) {
			return $path
		}
	}
	elseif ($vRequired -lt $v15) {
		if ($path = Get-MSBuildOldVersion $Version $Bitness) {
			return $path
		}
	}
	elseif ($vRequired -eq $vMax) {
		if ($path = Get-MSBuild15 $Bitness) {
			return $path
		}
		if ($path = Get-MSBuildOldLatest $Bitness) {
			return $path
		}
	}

	throw 'The specified version is not found.'
}
catch {
	Write-Error "Cannot resolve MSBuild $Version : $_"
}
