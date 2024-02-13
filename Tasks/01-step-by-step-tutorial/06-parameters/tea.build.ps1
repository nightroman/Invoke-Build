<#
New features:
	- new script parameters with reasonable defaults
	- tasks `add_tea` and `add_sugar` use parameters

Make default tea, one tea bag, no sugar:
	Invoke-Build

Make stronger tea with one sugar:
	Invoke-Build -TeaBags 2 -SugarLumps 1

Issue to resolve:
	- `add_sugar` is invoked for nothing when there is no sugar
#>

param(
	[int]$TeaBags = 1,
	[int]$SugarLumps
)

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
task add_sugar boil_water, {
	'adding sugar'
	$Script:Pot.sugar = $SugarLumps
}

task . boil_water, add_tea, add_sugar
