
<#
.Synopsis
	Example of scheduled tasks.

.Description
	This script is a demo of the custom repeat-task.
	See "Repeat.tasks.ps1" for the details of "repeat".

	The build file with repeats represents a schedule and repeats are normally
	invoked together (*). But they can be invoked individually, too. Tasks can
	reference repeats. Repeats can reference tasks.

	In other words, repeats are normal tasks with an extra feature: they are
	invoked only if specified time intervals are passed since previous runs.

.Example
	Invoke-Build * Repeat.build.ps1

	This command checks all scheduled tasks and invokes some of them as needed.
	It is supposed to be invoked periodically, manually or scheduled. In order
	to reset all times remove the file "Repeat.build.ps1.Repeat.clixml".
#>

# Import repeat-task definitions.
. .\Repeat.tasks.ps1

# Synopsis: Repeat every minute.
repeat task1 -Minutes 1 {
	"Doing $($Task.Name)..."
}

# Synopsis: Repeat every hour.
repeat task2 -Hours 1 {
	"Doing $($Task.Name)..."
}

# Synopsis: Repeat every day.
repeat task3 -Days 1 {
	"Doing $($Task.Name)..."
}
