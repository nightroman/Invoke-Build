<#
.Synopsis
	Tests of Resolve-MSBuild.ps1
#>

Import-Module .\Tools
if (Test-Unix) {return task unix}

$Program64 = $env:ProgramFiles
if (!($Program86 = ${env:ProgramFiles(x86)})) {$Program86 = $Program64}
$VS2017 = Test-Path "$Program86\Microsoft Visual Studio\2017"
$VS2019 = Test-Path "$Program86\Microsoft Visual Studio\2019"
$VS2022 = Test-Path "$Program64\Microsoft Visual Studio\2022"
$MSBuild14 = Test-Path 'HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\14.0'
$VSSetup = Get-Module VSSetup -ListAvailable
$Is64 = [IntPtr]::Size -eq 8

# from Resolve-MSBuild
function Get-MSBuild15Path {
	[CmdletBinding()] param(
		[string]$Version,
		[string]$Bitness
	)

	if ([System.IntPtr]::Size -eq 4 -or $Bitness -eq 'x86') {
		"MSBuild\$Version\Bin\MSBuild.exe"
	}
	else {
		"MSBuild\$Version\Bin\amd64\MSBuild.exe"
	}
}

task test15VSSetup -If $VS2017 {
	if (!$VSSetup) {Write-Warning 'VSSetup is not installed'}
	$r = Resolve-MSBuild 15.0
	Test-MSBuild $r
	assert ($r -like '*\15.0\*')

	$r = Resolve-MSBuild 15.0x86
	Test-MSBuild $r
	assert ($r -like '*\15.0\Bin\MSBuild.exe')

	# with spaces, #148
	$r2 = Resolve-MSBuild '  15.0  x86  '
	equals $r $r2
}

task test15VSSetup2019 -If $VS2019 {
	if (!$VSSetup) {Write-Warning 'VSSetup is not installed'}
	$r = Resolve-MSBuild 16.0
	Test-MSBuild $r
	assert ($r -like '*\Current\*')

	$r = Resolve-MSBuild 16.0x86
	Test-MSBuild $r
	assert ($r -like '*\Current\Bin\MSBuild.exe')

	# with spaces, #148
	$r2 = Resolve-MSBuild '  16.0  x86  '
	equals $r $r2
}

task test15VSSetup2022 -If $VS2022 {
	if (!$VSSetup) {Write-Warning 'VSSetup is not installed'}
	$r = Resolve-MSBuild 17.0
	Test-MSBuild $r
	assert ($r -like '*\Current\*')

	$r = Resolve-MSBuild 17.0x86
	Test-MSBuild $r
	assert ($r -like '*\Current\Bin\MSBuild.exe')

	# with spaces, #148
	$r2 = Resolve-MSBuild '  17.0  x86  '
	equals $r $r2
}

task test15Guess -If $VS2017 {
	Set-Alias Get-MSBuild15VSSetup Get-MSBuild15VSSetup2
	function Get-MSBuild15VSSetup2 {}

	$r = Resolve-MSBuild 15.0
	Test-MSBuild $r
	assert ($r -like '*\15.0\*')

	$r = Resolve-MSBuild 15.0x86
	Test-MSBuild $r
	assert ($r -like '*\15.0\Bin\MSBuild.exe')
}

task test15Guess2019 -If $VS2019 {
	Set-Alias Get-MSBuild15VSSetup Get-MSBuild15VSSetup2
	function Get-MSBuild15VSSetup2 {}

	$r = Resolve-MSBuild 16.0
	Test-MSBuild $r
	assert ($r -like '*\Current\*')

	$r = Resolve-MSBuild 16.0x86
	Test-MSBuild $r
	assert ($r -like '*\Current\Bin\MSBuild.exe')
}

task test15Guess2022 -If $VS2022 {
	Set-Alias Get-MSBuild15VSSetup Get-MSBuild15VSSetup2
	function Get-MSBuild15VSSetup2 {}

	$r = Resolve-MSBuild 17.0
	Test-MSBuild $r
	assert ($r -like '*\Current\*')

	$r = Resolve-MSBuild 17.0x86
	Test-MSBuild $r
	assert ($r -like '*\Current\Bin\MSBuild.exe')
}

task test14 -If $MSBuild14 {
	$r = Resolve-MSBuild 14.0
	Test-MSBuild $r
	assert ($r -like '*\14.0\*')

	$r = Resolve-MSBuild 14.0x86
	Test-MSBuild $r
	assert ($r -like '*\14.0\Bin\MSBuild.exe')
}

task test40 {
	$r = Resolve-MSBuild 4.0
	Test-MSBuild $r
	if ($Is64) {
		assert ($r -like '*\Microsoft.NET\Framework64\v4.0.*\MSBuild.exe')
	}
	else {
		assert ($r -like '*\Microsoft.NET\Framework\v4.0.*\MSBuild.exe')
	}

	$r = Resolve-MSBuild 4.0x86
	Test-MSBuild $r
	assert ($r -like '*\Microsoft.NET\Framework\v4.0.*\MSBuild.exe')
}

task testAll15 -If ($VS2017 -or $VS2019) {
	$r = Resolve-MSBuild
	Test-MSBuild $r
	if ($Is64) {
		assert ($r -like '*\Current\bin\amd64\MSBuild.exe' -or $r -like '*\15.0\bin\amd64\MSBuild.exe')
	}
	else {
		assert ($r -like '*\Current\bin\MSBuild.exe' -or $r -like '*\15.0\bin\MSBuild.exe')
	}

	$r = Resolve-MSBuild *x86
	Test-MSBuild $r
	assert ($r -like '*\Current\bin\MSBuild.exe' -or $r -like '*\15.0\bin\MSBuild.exe')
	equals $r (Resolve-MSBuild x86) # same but *
}

task testAll14 {
	Set-Alias Get-MSBuild15 Get-MSBuild15-2
	function Get-MSBuild15-2 {}

	$r = Resolve-MSBuild
	Test-MSBuild $r
	if ($MSBuild14) {
		if ($Is64) {
			assert ($r -like '*\14.0\bin\amd64\MSBuild.exe')
		}
		else {
			assert ($r -like '*\14.0\bin\MSBuild.exe')
		}
	}
	else {
		if ($Is64) {
			assert ($r -like '*\Microsoft.NET\Framework64\v4.0.*\MSBuild.exe')
		}
		else {
			assert ($r -like '*\Microsoft.NET\Framework\v4.0.*\MSBuild.exe')
		}
	}

	$r = Resolve-MSBuild *x86
	Test-MSBuild $r
	if ($MSBuild14) {
		assert ($r -like '*\14.0\bin\MSBuild.exe')
	}
	else {
		assert ($r -like '*\v4.0.*\MSBuild.exe')
	}
	equals $r (Resolve-MSBuild x86) # same but *
}

task missingOld {
	($r = try {Resolve-MSBuild 1.0} catch {$_})
	equals "$r" 'Cannot find MSBuild version: 1.0.'
	equals $r.InvocationInfo.ScriptName $BuildFile
}

task missingNew {
	($r = try {Resolve-MSBuild 15.1} catch {$_})
	equals "$r" 'Cannot find MSBuild version: 15.1.'
	equals $r.InvocationInfo.ScriptName $BuildFile
}

task missing15 {
	Set-Alias Get-MSBuild15 Get-MSBuild15-2
	function Get-MSBuild15-2 {}

	($r = try {Resolve-MSBuild 15.0} catch {$_})
	equals "$r" 'Cannot find MSBuild version: 15.0.'
	equals $r.InvocationInfo.ScriptName $BuildFile
}

task invalidVersion {
	($r = try {Resolve-MSBuild invalid} catch {$_})
	equals "$r" 'Invalid MSBuild version format: invalid.'
	equals $r.InvocationInfo.ScriptName $BuildFile
}

task alias-of-Resolve-MSBuild {
	$r = @(Get-Command Resolve-MSBuild)[0]
	equals "$($r.CommandType)" Alias
}

task Get-MSBuild15VSSetup {
	function Get-Module {1}
	function Import-Module {}
	function Get-VSSetupInstance {$it}
	function Select-VSSetupInstance {$Input}

	function New-It($Product, $InstallationPath, [version]$InstallationVersion='15.0') {
		$productIns = New-Object psobject
		$productIns | Add-Member -Type NoteProperty -Name Id -Value $Product
		$r = New-Object psobject
		$r | Add-Member -Type NoteProperty -Name Product -Value $productIns
		$r | Add-Member -Type NoteProperty -Name InstallationPath -Value $InstallationPath
		$r | Add-Member -Type NoteProperty -Name InstallationVersion -Value $InstallationVersion
		$r
	}

	$it = New-It Microsoft.VisualStudio.Product.Enterprise \2017\Enterprise
	($r = Resolve-MSBuild)
	equals $r "\2017\Enterprise\$(Get-MSBuild15Path 15.0)"

	$it = New-It Microsoft.VisualStudio.Product.Professional \2017\Professional
	($r = Resolve-MSBuild)
	equals $r "\2017\Professional\$(Get-MSBuild15Path 15.0)"

	$it = New-It Microsoft.VisualStudio.Product.Community \2017\Community
	($r = Resolve-MSBuild)
	equals $r "\2017\Community\$(Get-MSBuild15Path 15.0)"

	$it = New-It Microsoft.VisualStudio.Product.Something \2017\Something
	($r = Resolve-MSBuild)
	equals $r "\2017\Something\$(Get-MSBuild15Path 15.0)"

	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools \2017\BuildTools
		New-It Microsoft.VisualStudio.Product.Community \2017\Community
		New-It Microsoft.VisualStudio.Product.Enterprise \2017\Enterprise
		New-It Microsoft.VisualStudio.Product.Professional \2017\Professional
		New-It Microsoft.VisualStudio.Product.TeamExplorer \2017\TeamExplorer
	)
	($r = Resolve-MSBuild)
	equals $r "\2017\Enterprise\$(Get-MSBuild15Path 15.0)"

	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools \2017\BuildTools
		New-It Microsoft.VisualStudio.Product.Community \2017\Community
		New-It Microsoft.VisualStudio.Product.Professional \2017\Professional
		New-It Microsoft.VisualStudio.Product.TeamExplorer \2017\TeamExplorer
	)
	($r = Resolve-MSBuild)
	equals $r "\2017\Professional\$(Get-MSBuild15Path 15.0)"

	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools \2017\BuildTools
		New-It Microsoft.VisualStudio.Product.Community \2017\Community
		New-It Microsoft.VisualStudio.Product.TeamExplorer \2017\TeamExplorer
	)
	($r = Resolve-MSBuild)
	equals $r "\2017\Community\$(Get-MSBuild15Path 15.0)"

	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools \2017\BuildTools
		New-It Microsoft.VisualStudio.Product.TeamExplorer \2017\TeamExplorer
	)
	($r = Resolve-MSBuild)
	equals $r "\2017\BuildTools\$(Get-MSBuild15Path 15.0)"

	# -Latest 1 candidate
	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools \2017\BuildTools 15.1
		New-It Microsoft.VisualStudio.Product.Community \2017\Community 15.1
		New-It Microsoft.VisualStudio.Product.TeamExplorer \2017\TeamExplorer 15.2
	)
	($r = Resolve-MSBuild -Latest)
	equals $r "\2017\TeamExplorer\$(Get-MSBuild15Path 15.0)"

	# -Latest 2 candidates
	$it = @(
		New-It Microsoft.VisualStudio.Product.TeamExplorer \2017\TeamExplorer 15.2
		New-It Microsoft.VisualStudio.Product.BuildTools \2017\BuildTools 15.1
		New-It Microsoft.VisualStudio.Product.Community \2017\Community 15.2
	)
	($r = Resolve-MSBuild -Latest)
	equals $r "\2017\Community\$(Get-MSBuild15Path 15.0)"

    # VS2019 if version=* then get latest among same products
	$it = @(
		New-It Microsoft.VisualStudio.Product.Enterprise \2019\Enterprise 16.0
		New-It Microsoft.VisualStudio.Product.Enterprise \2017\Enterprise 15.0
	)
	($r = Resolve-MSBuild)
	equals $r "\2019\Enterprise\$(Get-MSBuild15Path Current)"
}

task Get-MSBuild15Guess {
	Set-Alias Get-MSBuild15VSSetup Get-MSBuild15VSSetup2
	function Get-MSBuild15VSSetup2 {}
	function Test-Path {$true}
	function Get-Item {$it}

    function New-It($FullName, [version]$FileVersion='15.0') {
    	$r = New-Object psobject
    	$r | Add-Member -Type NoteProperty -Name FullName -Value $FullName
		$info = New-Object psobject
		$info | Add-Member -Type NoteProperty -Name FileVersion -Value $FileVersion
		$r | Add-Member -Type NoteProperty -Name VersionInfo -Value $info
    	$r
    }

	$it = New-It ..\Enterprise\..
	($r = Resolve-MSBuild)
	equals $r ..\Enterprise\..

	$it = New-It ..\Professional\..
	($r = Resolve-MSBuild)
	equals $r ..\Professional\..

	$it = New-It ..\Community\..
	($r = Resolve-MSBuild)
	equals $r ..\Community\..

	$it = New-It ..\Something\..
	($r = Resolve-MSBuild)
	equals $r ..\Something\..

	$it = @(
		New-It ..\BuildTools\..
		New-It ..\Community\..
		New-It ..\Enterprise\..
		New-It ..\Professional\..
		New-It ..\TeamExplorer\..
	)
	($r = Resolve-MSBuild)
	equals $r ..\Enterprise\..

	$it = @(
		New-It ..\BuildTools\..
		New-It ..\Community\..
		New-It ..\Professional\..
		New-It ..\TeamExplorer\..
	)
	($r = Resolve-MSBuild)
	equals $r ..\Professional\..

	$it = @(
		New-It ..\BuildTools\..
		New-It ..\Community\..
		New-It ..\TeamExplorer\..
	)
	($r = Resolve-MSBuild)
	equals $r ..\Community\..

	$it = @(
		New-It ..\TeamExplorer\..
		New-It ..\BuildTools\..
	)
	($r = Resolve-MSBuild)
	equals $r ..\BuildTools\..

	# -Latest 1 candidate
	$it = @(
		New-It ..\BuildTools\.. 15.1
		New-It ..\Community\.. 15.1
		New-It ..\TeamExplorer\.. 15.2
	)
	($r = Resolve-MSBuild -Latest)
	equals $r ..\TeamExplorer\..

	# -Latest 2 candidates
	$it = @(
		New-It ..\TeamExplorer\.. 15.2
		New-It ..\BuildTools\.. 15.1
		New-It ..\Community\.. 15.2
	)
	($r = Resolve-MSBuild -Latest)
	equals $r ..\Community\..

    # VS2019 if version=* then get latest among same products
	$it = @(
		New-It ..\2019\Enterprise\.. 16.0
		New-It ..\2017\Enterprise\.. 15.0
	)
	($r = Resolve-MSBuild)
	equals $r ..\2019\Enterprise\..
}

task MinimumVersionBad {
	($r = try { Resolve-MSBuild -MinimumVersion 9999.0 } catch { $_ })
	assert ("$r" -match '^MSBuild resolved version \d+\.\d+\.\d+\.\d+ is less than required minimum 9999\.0\.$')
}

task MinimumVersionGood {
	# default latest and its version
	($MSBuild = Resolve-MSBuild)
	$ver = [Version](& $MSBuild -version -nologo)

	# ditto with -MinimumVersion
	$r1 = Resolve-MSBuild -MinimumVersion $ver
	equals $r1 $MSBuild

	# x86 latest and its version
	($MSBuild = Resolve-MSBuild x86)
	$ver = [Version](& $MSBuild -version -nologo)

	# ditto with -MinimumVersion
	$r2 = Resolve-MSBuild x86 $ver
	equals $r2 $MSBuild

	# on x64 results are different
	if ($Is64) {
		assert ($r1 -ne $r2)
	}
}
