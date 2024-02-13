<#
New features:
	- parameter `$Tasks` and bootstrap block to run the script directly
	- InvokeBuild is installed automatically when needed

Run the build script directly:
	./tea.build.ps1 -TeaBags 2 -SugarLumps 1

But it is still Invoke-Build:
	Invoke-Build -TeaBags 2 -SugarLumps 1
#>

param(
	[Parameter(Position=0)]
	[string[]]$Tasks
	,
	[int]$TeaBags = 1
	,
	[int]$SugarLumps
)

# bootstrap
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
	$ErrorActionPreference = 1
	if (!(Get-Command Invoke-Build -ErrorAction Ignore)) {
		Write-Host -ForegroundColor Cyan 'Installing module InvokeBuild...'
		Install-Module InvokeBuild -Scope CurrentUser -Force
		Import-Module InvokeBuild
	}
	return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

Exit-Build {
	$Script:Pot
}

# Synopsis: Boils a pot of water.
task boil_water {
	'boiling water'
	$Script:Pot = @{}
}

# Synopsis: Adds tea bags.
task add_tea boil_water, {
	'adding tea'
	$Script:Pot.tea = $TeaBags
}

# Synopsis: Adds sugar lumps.
task add_sugar -If { $SugarLumps -ge 1 } -Jobs boil_water, {
	'adding sugar'
	$Script:Pot.sugar = $SugarLumps
}

task . boil_water, add_tea, add_sugar
