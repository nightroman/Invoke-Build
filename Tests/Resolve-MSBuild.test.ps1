
<#
.Synopsis
	Tests of Resolve-MSBuild.ps1

.Example
	Invoke-Build * Resolve-MSBuild.test.ps1
#>

. ./Shared.ps1

if (!($ProgramFiles = ${env:ProgramFiles(x86)})) {$ProgramFiles = $env:ProgramFiles}
$VS2017 = Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017"
$VSSetup = Get-Module VSSetup -ListAvailable
$Is64 = [IntPtr]::Size -eq 8

# from Resolve-MSBuild
function Get-MSBuild15Path($Bitness) {
	if ([System.IntPtr]::Size -eq 4 -or $Bitness -eq 'x86') {
		'MSBuild\15.0\Bin\MSBuild.exe'
	}
	else {
		'MSBuild\15.0\Bin\amd64\MSBuild.exe'
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
}

task test15Guess -If $VS2017 {
	. Set-Mock Get-MSBuild15VSSetup {}

	$r = Resolve-MSBuild 15.0
	Test-MSBuild $r
	assert ($r -like '*\15.0\*')

	$r = Resolve-MSBuild 15.0x86
	Test-MSBuild $r
	assert ($r -like '*\15.0\Bin\MSBuild.exe')
}

task test14 {
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

task testAll15 -If $VS2017 {
	$r = Resolve-MSBuild
	Test-MSBuild $r
	if ($Is64) {
		assert ($r -like '*\15.0\bin\amd64\MSBuild.exe')
	}
	else {
		assert ($r -like '*\15.0\bin\MSBuild.exe')
	}

	$r = Resolve-MSBuild *x86
	Test-MSBuild $r
	assert ($r -like '*\15.0\bin\MSBuild.exe')
	equals $r (Resolve-MSBuild x86) # same but *
}

task testAll14 {
	. Set-Mock Get-MSBuild15 {}

	$r = Resolve-MSBuild
	Test-MSBuild $r
	if ($Is64) {
		assert ($r -like '*\14.0\bin\amd64\MSBuild.exe')
	}
	else {
		assert ($r -like '*\14.0\bin\MSBuild.exe')
	}

	$r = Resolve-MSBuild *x86
	Test-MSBuild $r
	assert ($r -like '*\14.0\bin\MSBuild.exe')
	equals $r (Resolve-MSBuild x86) # same but *
}

task missingOld {
	($r = try {Resolve-MSBuild 1.0} catch {$_})
	assert (($r | Out-String) -like '*Cannot resolve MSBuild 1.0 :*Resolve-MSBuild.test.ps1:*')
}

task missingNew {
	($r = try {Resolve-MSBuild 15.1} catch {$_})
	assert (($r | Out-String) -like '*Cannot resolve MSBuild 15.1 :*Resolve-MSBuild.test.ps1:*')
}

task missing15 {
	. Set-Mock Get-MSBuild15 {}
	($r = try {Resolve-MSBuild 15.0} catch {$_})
	assert (($r | Out-String) -like '*Cannot resolve MSBuild 15.0 : *Resolve-MSBuild.test.ps1:*')
}

task invalidVersion {
	($r = try {Resolve-MSBuild invalid} catch {$_})
	assert (($r | Out-String) -like '*Cannot resolve MSBuild invalid :*"invalid"*Resolve-MSBuild.test.ps1:*')
}

task alias-of-Resolve-MSBuild {
	$r = @(Get-Command Resolve-MSBuild)[0]
	equals "$($r.CommandType)" Alias
}

task Get-MSBuild15VSSetup {
	. Set-Mock Get-Module {1}
	. Set-Mock Import-Module {}
    . Set-Mock Get-VSSetupInstance {$it}
    . Set-Mock Select-VSSetupInstance {$Input}

    function New-It($Product, $InstallationPath, $InstallationVersion) {
    	$r = New-Object psobject
    	$r | Add-Member -Type NoteProperty -Name Product -Value $Product
    	$r | Add-Member -Type NoteProperty -Name InstallationPath -Value $InstallationPath
    	$r | Add-Member -Type NoteProperty -Name InstallationVersion -Value $InstallationVersion
    	$r
    }

	$it = New-It Microsoft.VisualStudio.Product.Enterprise Enterprise
	($r = Resolve-MSBuild)
	equals $r "Enterprise\$(Get-MSBuild15Path)"

	$it = New-It Microsoft.VisualStudio.Product.Professional Professional
	($r = Resolve-MSBuild)
	equals $r "Professional\$(Get-MSBuild15Path)"

	$it = New-It Microsoft.VisualStudio.Product.Community Community
	($r = Resolve-MSBuild)
	equals $r "Community\$(Get-MSBuild15Path)"

	$it = New-It Microsoft.VisualStudio.Product.Something Something
	($r = Resolve-MSBuild)
	equals $r "Something\$(Get-MSBuild15Path)"

	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools BuildTools
		New-It Microsoft.VisualStudio.Product.Community Community
		New-It Microsoft.VisualStudio.Product.Enterprise Enterprise
		New-It Microsoft.VisualStudio.Product.Professional Professional
		New-It Microsoft.VisualStudio.Product.TeamExplorer TeamExplorer
	)
	($r = Resolve-MSBuild)
	equals $r "Enterprise\$(Get-MSBuild15Path)"

	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools BuildTools
		New-It Microsoft.VisualStudio.Product.Community Community
		New-It Microsoft.VisualStudio.Product.Professional Professional
		New-It Microsoft.VisualStudio.Product.TeamExplorer TeamExplorer
	)
	($r = Resolve-MSBuild)
	equals $r "Professional\$(Get-MSBuild15Path)"

	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools BuildTools
		New-It Microsoft.VisualStudio.Product.Community Community
		New-It Microsoft.VisualStudio.Product.TeamExplorer TeamExplorer
	)
	($r = Resolve-MSBuild)
	equals $r "Community\$(Get-MSBuild15Path)"

	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools BuildTools
		New-It Microsoft.VisualStudio.Product.TeamExplorer TeamExplorer
	)
	($r = Resolve-MSBuild)
	equals $r "BuildTools\$(Get-MSBuild15Path)"

	# -Latest 1 candidate
	$it = @(
		New-It Microsoft.VisualStudio.Product.BuildTools BuildTools ([version]'15.1')
		New-It Microsoft.VisualStudio.Product.Community Community ([version]'15.1')
		New-It Microsoft.VisualStudio.Product.TeamExplorer TeamExplorer ([version]'15.2')
	)
	($r = Resolve-MSBuild -Latest)
	equals $r "TeamExplorer\$(Get-MSBuild15Path)"

	# -Latest 2 candidates
	$it = @(
		New-It Microsoft.VisualStudio.Product.TeamExplorer TeamExplorer ([version]'15.2')
		New-It Microsoft.VisualStudio.Product.BuildTools BuildTools ([version]'15.1')
		New-It Microsoft.VisualStudio.Product.Community Community ([version]'15.2')
	)
	($r = Resolve-MSBuild -Latest)
	equals $r "Community\$(Get-MSBuild15Path)"
}

task Get-MSBuild15Guess {
	. Set-Mock Get-MSBuild15VSSetup {}
	. Set-Mock Test-Path {$true}
	. Set-Mock Get-Item {$it}

    function New-It($FullName, $FileVersion) {
    	$r = New-Object psobject
    	$r | Add-Member -Type NoteProperty -Name FullName -Value $FullName
    	if ($FileVersion) {
    		$info = New-Object psobject
    		$info | Add-Member -Type NoteProperty -Name FileVersion -Value $FileVersion
    		$r | Add-Member -Type NoteProperty -Name VersionInfo -Value $info
    	}
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
		New-It ..\BuildTools\.. ([version] '15.1')
		New-It ..\Community\.. ([version] '15.1')
		New-It ..\TeamExplorer\.. ([version] '15.2')
	)
	($r = Resolve-MSBuild -Latest)
	equals $r ..\TeamExplorer\..

	# -Latest 2 candidates
	$it = @(
		New-It ..\TeamExplorer\.. ([version] '15.2')
		New-It ..\BuildTools\.. ([version] '15.1')
		New-It ..\Community\.. ([version] '15.2')
	)
	($r = Resolve-MSBuild -Latest)
	equals $r ..\Community\..
}
