
<#
.Synopsis
	Example of ask-tasks.

.Description
	This script is a demo of the custom ask-task.
	See "Ask.tasks.ps1" for the details of "ask".

.Example
	Invoke-Build MakeTea
#>

. ./Ask.tasks.ps1

# Synopsis: An ask-task with the prompt and other tasks.
ask MakeTea -Prompt 'Make some tea?' BoilWater, AddSugar, {
	'Serving tea'
}

# Synopsis: A normal task referenced by MakeTea.
task BoilWater {
	'Boiling water'
}

# Synopsis: An ask-task referenced by MakeTea.
ask AddSugar {
	'Adding sugar'
}
