<#
Resolved:
	- cannot run just `add_tea` or `add_sugar`, they need `boil_water`

New features:
	- `add_tea` and `add_sugar` reference `boil_water` because they need it

Notes:
	- `boil_water` is invoked once even if referenced many times, directly or not
	- we can now omit `boil_water` in the default task but being explicit is good
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
task add_tea boil_water, {
	'adding tea'
	$Script:Pot.tea = 1
}

# Synopsis: Adds sugar lumps.
task add_sugar boil_water, {
	'adding sugar'
	$Script:Pot.sugar = 1
}

task . boil_water, add_tea, add_sugar
