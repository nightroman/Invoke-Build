<#
New features:
	- the default task `.` is our objective "make tea"
	- special task comments `# Synopsis:`

Run the default task, "make tea":
	Invoke-Build
	Invoke-Build .

Show the task list with comments:
	Invoke-Build ?
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
