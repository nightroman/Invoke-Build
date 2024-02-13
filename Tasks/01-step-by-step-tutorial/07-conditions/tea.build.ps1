<#
Resolved:
	- `add_sugar` is invoked for nothing when there is no sugar

New features:
	- `add_sugar` task condition, it runs with one or more sugar
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
task add_sugar -If { $SugarLumps -ge 1 } -Jobs boil_water, {
	'adding sugar'
	$Script:Pot.sugar = $SugarLumps
}

task . boil_water, add_tea, add_sugar
