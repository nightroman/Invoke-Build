<#
Initial steps:
	- create a file named like `*.build.ps1`, `tea.build.ps1`
	- add a task, `boil_water`, at least one is required

Run the task boil_water:
	Invoke-Build
	Invoke-Build boil_water
#>

task boil_water {
	'boiling water'
}
