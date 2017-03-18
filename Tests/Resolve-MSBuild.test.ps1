
<#
.Synopsis
	Tests of Resolve-MSBuild.ps1

.Example
	Invoke-Build * Resolve-MSBuild.test.ps1
#>

if (!($ProgramFiles = ${env:ProgramFiles(x86)})) {$ProgramFiles = $env:ProgramFiles}
$VS2017 = Test-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017"
$VSSetup = Get-Module VSSetup -ListAvailable

function Test-MSBuild([Parameter()]$Path) {
	if ($Path -notlike '*\MSBuild.exe') {Write-Error "Unexpected path $Path"}
	if (![System.IO.File]::Exists($Path)) {Write-Error "Missing file $Path"}
	$Path
}

$calls = @{}
function Get-Nothing {
	$calls.Nothing = 1 + $calls['Nothing']
}

function Set-Mock($Alias, $Command) {
	Set-Alias $Alias $Command -Scope 1
	$calls.Clear()
}

task test15VSSetup -If $VS2017 {
	if (!$VSSetup) {Write-Warning 'VSSetup is not installed'}
	$r = Resolve-MSBuild 15.0
	Test-MSBuild $r
	assert ($r -like '*\15.0\*')
}

task test15Guess -If $VS2017 {
	Set-Mock Get-MSBuild15VSSetup Get-Nothing
	$r = Resolve-MSBuild 15.0
	Test-MSBuild $r
	equals $calls.Nothing 1
	assert ($r -like '*\15.0\*')
}

task test14 {
	$r = Resolve-MSBuild 14.0
	Test-MSBuild $r
	assert ($r -like '*\14.0\*')
}

task test40 {
	$r = Resolve-MSBuild 4.0
	Test-MSBuild $r
	assert ($r -like '*\Microsoft.NET\Framework*\v4.0.*\MSBuild.exe')
}

task testAll15 -If $VS2017 {
	$r = Resolve-MSBuild
	Test-MSBuild $r
	assert ($r -like '*\15.0\*')
}

task testAll14 {
	Set-Mock Get-MSBuild15VSSetup Get-Nothing
	Set-Mock Get-MSBuild15Guess Get-Nothing
	$r = Resolve-MSBuild
	Test-MSBuild $r
	equals $calls.Nothing 2
	assert ($r -like '*\14.0\*')
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
	Set-Mock Get-MSBuild15 Get-Nothing
	($r = try {Resolve-MSBuild 15.0} catch {$_})
	assert (($r | Out-String) -like '*Cannot resolve MSBuild 15.0 : *Resolve-MSBuild.test.ps1:*')
	equals $calls.Nothing 1
}

task invalidVersion {
	($r = try {Resolve-MSBuild invalid} catch {$_})
	assert (($r | Out-String) -like '*Cannot resolve MSBuild invalid :*"invalid"*Resolve-MSBuild.test.ps1:*')
}
