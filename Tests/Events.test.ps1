
<#
.Synopsis
	Tests build events.

.Description
	The tasks and events of this script set a noise location and check that on
	calling the current location is restored to $BuildRoot.

	Task and job event scopes must be the same for a task.

	Events try to set the constant variable $Task and check expected failures.

.Example
	Invoke-Build * Events.test.ps1
#>

Set-Location $HOME

function Assert-CannotSetTask {
	$r = try {$Task = 1} catch {$_}
	equals $r.FullyQualifiedErrorId VariableNotWritable
}

# Enter-Build is called before the first task in the script scope.
# Its local definitions are available for tasks and event blocks.
Enter-Build {
	"Enter build"
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
}

# Exit-Build is called after the last task or on build failures.
Exit-Build {
	"Exit build"
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
}

# Enter-BuildTask is called before each task.
# The scope is new, the parent of task actions.
Enter-BuildTask {
	$TaskName = $Task.Name # set just here, check later
	'Enter task {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	. Assert-CannotSetTask
}

# Exit-BuildTask is called after each task.
# The scope is the same as for Enter-BuildTask.
Exit-BuildTask {
	equals $TaskName $Task.Name # the same scope
	'Exit task {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	. Assert-CannotSetTask
}

# Enter-BuildJob is called before each action.
# The scope is the same as for Enter-BuildTask.
Enter-BuildJob {
	equals $TaskName $Task.Name # the same scope
	'Enter job {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	. Assert-CannotSetTask
}

# Exit-BuildJob is called after each script job.
# The scope is the same as for Enter-BuildTask.
Exit-BuildJob {
	equals $TaskName $Task.Name # the same scope
	'Exit job {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	. Assert-CannotSetTask
}

task Task1 {
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	equals $Task.Name 'Task1' #! name has the original case
	$Task = 'can set'
}

#! reference has lower case
task Task2 task1, {
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	equals $Task.Name 'Task2' #! name has the original case
	$Task = 'can set'
}

#! reference has lower case
task . task2
