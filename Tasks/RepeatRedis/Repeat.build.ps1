<#
.Synopsis
	Example of repeat-tasks.

.Description
	See "Repeat.tasks.ps1" for the details of `repeat`.

.Example
	Invoke-Build * Repeat.build.ps1

	This command checks all repeat-tasks and invokes some of them as needed.
	The script is supposed to be invoked periodically, manually or scheduled.
#>

# Import helpers and specify the task prefix.
. .\Repeat.tasks.ps1 temp:repeat:test-repeat-tasks:

# Synopsis: Repeat every minute.
task task1 (repeat 0:1 {
	"Doing $($Task.Name)..."
})

# Synopsis: Repeat every hour.
task task2 (repeat 1:0 {
	"Doing $($Task.Name)..."
})

# Synopsis: Repeat every day.
task task3 (repeat 1:0:0:0 {
	"Doing $($Task.Name)..."
})
