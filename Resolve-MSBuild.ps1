
<#PSScriptInfo
.VERSION 1.3.0
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
	It is designed for MSBuild 15.0, 14.0, 12.0, 4.0, 3.5, 2.0.

	For MSBuild 15.0 the command uses VSSetup module from PSGallery.
	If it is not installed then some default locations are checked.
	VSSetup module is required for not default installations.

	MSBuild 15.0 resolution: the latest version (if requested by -Latest), then
	Enterprise, Professional, Community, BuildTools, other products. If this is
	not suitable then use VSSetup module and choose differently.

	For MSBuild 2.0-14.0 the information is taken from the registry.

.Parameter Version
		Specifies the required MSBuild version. If it is omitted, empty, or *
		then the command finds and returns the latest installed version path.
		The optional suffix x86 tells to use 32-bit MSBuild.
		Known versions: 15.0, 14.0, 12.0, 4.0, 3.5, 2.0
.Parameter Latest
		Tells to select the latest (minor) version if there are 2+ products
		with the same (major) version. For example, 15.0 actually gets 15.x
		and Latest tells to choose the version before the product.

.Outputs
	The full path to MSBuild.exe

.Example
	Resolve-MSBuild 15.0
	Gets location of MSBuild installed with Visual Studio 2017.

.Link
	https://www.powershellgallery.com/packages/VSSetup
#>

[OutputType([string])]
[CmdletBinding()]
param(
	[string]$Version,
	[switch]$Latest
)

function Get-MSBuild15Path($Bitness) {
	if ([System.IntPtr]::Size -eq 4 -or $Bitness -eq 'x86') {
		'MSBuild\15.0\Bin\MSBuild.exe'
	}
	else {
		'MSBuild\15.0\Bin\amd64\MSBuild.exe'
	}
}

function Get-MSBuild15VSSetup($Bitness, [switch]$Latest, [switch]$Prerelease) {
	if (!(Get-Module VSSetup)) {
		if (!(Get-Module VSSetup -ListAvailable)) {return}
		Import-Module VSSetup
	}

	$items = @(
		Get-VSSetupInstance -Prerelease:$Prerelease |
		Select-VSSetupInstance -Version 15.0 -Require Microsoft.Component.MSBuild -Product *
	)
	if (!$items) {
		if (!$Prerelease) {
			Get-MSBuild15VSSetup -Bitness:$Bitness -Latest:$Latest -Prerelease
		}
		return
	}

	if ($items.Count -ge 2) {
		$byProduct = {
			if ($_.Product -eq 'Microsoft.VisualStudio.Product.Enterprise') {4}
			elseif ($_.Product -eq 'Microsoft.VisualStudio.Product.Professional') {3}
			elseif ($_.Product -eq 'Microsoft.VisualStudio.Product.Community') {2}
			elseif ($_.Product -eq 'Microsoft.VisualStudio.Product.BuildTools') {1}
			else {0}
		}
		if ($Latest) {
			$items = $items | Sort-Object InstallationVersion, $byProduct
		}
		else {
			$items = $items | Sort-Object $byProduct
		}
	}

	Join-Path ($items[-1].InstallationPath) (Get-MSBuild15Path $Bitness)
}

function Get-MSBuild15Guess($Bitness, [switch]$Latest, [switch]$Prerelease) {
	$Folder = if ($Prerelease) {'Preview'} else {'2017'}
	if (!($root = ${env:ProgramFiles(x86)})) {$root = $env:ProgramFiles}

	$items = @(Get-Item "$root\Microsoft Visual Studio\$Folder\*\$(Get-MSBuild15Path $Bitness)" -ErrorAction 0)
	if (!$items) {
		if (!$Prerelease) {
			Get-MSBuild15Guess -Bitness:$Bitness -Latest:$Latest -Prerelease
		}
		return
	}

	if ($items.Count -ge 2) {
		$byProduct = {
			if ($_.FullName -like '*\Enterprise\*') {4}
			elseif ($_.FullName -like '*\Professional\*') {3}
			elseif ($_.FullName -like '*\Community\*') {2}
			elseif ($_.FullName -like '*\BuildTools\*') {1}
			else {0}
		}
		if ($Latest) {
			$items = $items | Sort-Object {$_.VersionInfo.FileVersion}, $byProduct
		}
		else {
			$items = $items | Sort-Object $byProduct
		}
	}

	$items[-1].FullName
}

function Get-MSBuild15($Bitness, [switch]$Latest) {
	if ($path = Get-MSBuild15VSSetup $Bitness -Latest:$Latest) {
		$path
	}
	else {
		Get-MSBuild15Guess $Bitness -Latest:$Latest
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
		if ($path = Get-MSBuild15 $Bitness -Latest:$Latest) {
			return $path
		}
	}
	elseif ($vRequired -lt $v15) {
		if ($path = Get-MSBuildOldVersion $Version $Bitness) {
			return $path
		}
	}
	elseif ($vRequired -eq $vMax) {
		if ($path = Get-MSBuild15 $Bitness -Latest:$Latest) {
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
