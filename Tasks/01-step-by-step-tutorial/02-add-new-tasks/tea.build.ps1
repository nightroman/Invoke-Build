<#
New features:
	- new tasks `add_tea` and `add_sugar`

Run any task or combinations:
	Invoke-Build boil_water
	Invoke-Build add_tea
	Invoke-Build add_sugar
	Invoke-Build boil_water, add_tea, add_sugar

Issue to solve:
	- the last command "make tea" is rather verbose for the objective
#>

task boil_water {
	'boiling water'
}

task add_tea {
	'adding tea'
}

task add_sugar {
	'adding sugar'
}
