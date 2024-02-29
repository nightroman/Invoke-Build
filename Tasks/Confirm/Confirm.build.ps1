<#
.Synopsis
	Confirm-Build example.

.Description
	This script shows how to:
	- use Confirm-Build for task confirmations
	- "Yes to All", e.g. when non interactive

.Example
	> Invoke-Build MakeTea

.Example
	> Invoke-Build MakeTea -Quiet
#>

param(
	[switch]$Quiet
)

# On $Quiet, redefine Confirm-Build as true.
if ($Quiet) {function Confirm-Build {$true}}

# Synopsis: A task with default confirmation.
task MakeTea -If {Confirm-Build} BoilWater, AddSugar, {
	'Serving tea'
}

# Synopsis: Just a normal task.
task BoilWater {
	'Boiling water'
}

# Synopsis: A task with custom confirmation.
task AddSugar -If {Confirm-Build 'Add some sugar?'} {
	'Adding sugar'
}
