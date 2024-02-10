<#
New features:
	- the task `boil_water` creates `$Script:Pot`
	- `add_tea`, `add_sugar` update `$Script:Pot`
	- `Exit-Build` is used to show `$Script:Pot`

Issue to resolve:
	- cannot run just `add_tea` or `add_sugar`, they need `boil_water`
#>

Exit-Build {
	$Script:Pot
}

# Synopsis: Boils a pot of water.
task boil_water {
	'boiling water'
	$Script:Pot = @{}
}

# Synopsis: Adds tea bags.
task add_tea {
	'adding tea'
	$Script:Pot.tea = 1
}

# Synopsis: Adds sugar lumps.
task add_sugar {
	'adding sugar'
	$Script:Pot.sugar = 1
}

task . boil_water, add_tea, add_sugar
