<#
.Synopsis
	Example of repeat-tasks using Redis.

.Description
	See "Repeat.tasks.ps1" for the details.

	task1 uses Write-TaskLog to write task messages to Redis.
	task1 fails if the switch Fail is set, see errors in Redis.

.Example
	Invoke-Build *

	This command checks all repeat-tasks and invokes some of them as needed.
	The script is supposed to be invoked periodically, manually or scheduled.
#>

param(
	[switch]$Fail
)

# Import helpers and specify Redis prefix for tasks.
. .\Repeat.tasks.ps1 zoo:repeat:test-repeat-tasks:

# Synopsis: Repeat every minute, write task log, optionally fail.
task task1 (repeat 0:1 {
	"Working..."
	Write-TaskLog "Task log message."
	if ($fail) {
		throw "Oops, something is wrong."
	}
})

# Synopsis: Repeat every hour.
task task2 (repeat 1:0 {
	"Working..."
})

# Synopsis: Repeat every day.
task task3 (repeat 1:0:0:0 {
	"Working..."
})
