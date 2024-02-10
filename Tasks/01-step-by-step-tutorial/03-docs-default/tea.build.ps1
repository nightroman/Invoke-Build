<#
New features:
	- documentation comments `# Synopsis:`
	- the default task `.`

Show tasks with their details:
	Invoke-Build ?

Run the default task:
	Invoke-Build
	Invoke-Build .
#>

# Synopsis: Boils a pot of water.
task boil_water {
	'boiling water'
}

# Synopsis: Adds tea bags.
task add_tea {
	'adding tea'
}

# Synopsis: Adds sugar lumps.
task add_sugar {
	'adding sugar'
}

task . boil_water, add_tea, add_sugar
