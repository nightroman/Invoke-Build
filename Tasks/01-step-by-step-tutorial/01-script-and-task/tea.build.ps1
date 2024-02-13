<#
Initial steps:
	- create a file named like `*.build.ps1`: `tea.build.ps1`
	- add a task, at least one is required: `boil_water`

Run the task `boil_water`:
	Invoke-Build
	Invoke-Build boil_water
#>

task boil_water {
	'boiling water'
}
