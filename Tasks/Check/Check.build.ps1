
<#
.Synopsis
	Example of a check list.

.Description
	This script is a demo of the custom check-task.
	See "Check.tasks.ps1" for the details of "check".

.Example
	Invoke-Build * Check.build.ps1

	When the prompt is shown press enter for some tasks to simulate "Passed" or
	[Ctrl-C] to simulate "Failed". Then invoke the same command again (simulate
	resolved issues). Passed tasks will be skipped and the prompt will be shown
	for the failed task.

	Continue until all checks are passed. In order to restart all checks again,
	remove the file "Check.build.ps1.Check.clixml".
#>

# Import check-task definitions.
. .\Check.tasks.ps1

# Synopsis: It is a special check-task.
check task.1 {
	Read-Host "Do $($Task.Name) and press enter"
}

# Synopsis: It is a normal task referencing check-tasks.
task task.2 task.2.1, task.2.2

# Synopsis: Yet another special check-task.
check task.2.1 {
	Read-Host "Do $($Task.Name) and press enter"
}

# Synopsis: A check-task references other checks.
check task.2.2 task.2.2.1, task.2.2.2, {
	Read-Host "Do $($Task.Name) and press enter"
}

# Synopsis: Yet another special check-task.
check task.2.2.1 {
	Read-Host "Do $($Task.Name) and press enter"
}

# Synopsis: Yet another special check-task.
check task.2.2.2 {
	Read-Host "Do $($Task.Name) and press enter"
}
