
<#
.Synopsis
	Demo of event functions.

.Example
	Invoke-Build . Events.build.ps1
#>

# Enter-BuildScript is called before the first task in the script scope. Its
# local variables become available for all tasks and other event functions.
function Enter-BuildScript {
	"Enter script"
}

# Exit-BuildScript is called after the last task or on build failures.
function Exit-BuildScript {
	"Exit script"
}

# Enter-BuildTask is called before each task. It takes one argument - the task.
# The scope is new, the parent for the task script jobs.
function Enter-BuildTask($Task) {
	'Enter task {0}' -f $Task.Name
}

# Exit-BuildTask is called after each task. Arguments and the scope are the
# same as for Enter-BuildTask.
function Exit-BuildTask($Task) {
	'Exit task {0}' -f $Task.Name
}

# Enter-BuildJob is called before each script job. It takes two arguments - the
# task and the job number. The scope is the same as for Enter-BuildTask.
function Enter-BuildJob($Task, $Number) {
	'Enter job {1} of {0}' -f $Task.Name, $Number
}

# Exit-BuildJob is called after each script job. Arguments and the scope are
# the same as for Enter-BuildJob.
function Exit-BuildJob($Task, $Number) {
	'Exit job {1} of {0}' -f $Task.Name, $Number
}

task Task1 {
}

task Task2 Task1, {
}

task . Task2
