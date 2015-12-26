
<#
.Synopsis
	Tests of event functions.

.Description
	The tasks and events of this script sets a noise location and check that on
	calling the location is restored to $BuildRoot.

	Check task and job event scopes, they must be the same for a task.

	Events try to set the constant variable $Task and check expected failures.

.Example
	Invoke-Build * Events.test.ps1
#>

$err = '*Cannot overwrite variable Task because it is read-only or constant.*'
Set-Location $HOME

# Enter-Build is called before the first task in the script scope. Its local
# variables become available for all tasks and other event functions.
function Enter-Build {
	"Enter build"
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
}

# Exit-Build is called after the last task or on build failures.
function Exit-Build {
	"Exit build"
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
}

# Enter-BuildTask is called before each task.
# The scope is new, the parent for the task script jobs.
function Enter-BuildTask {
	$TaskName = $Task.Name # set just here, check later
	'Enter task {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	$$ = try {$Task = 1} catch {$_}
	assert ($$ -like $err)
}

# Exit-BuildTask is called after each task.
# The scope is the same as for Enter-BuildTask.
function Exit-BuildTask {
	equals $TaskName $Task.Name # the same scope
	'Exit task {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	$$ = try {$Task = 1} catch {$_}
	assert ($$ -like $err)
}

# Enter-BuildJob is called before each script job. Its argument is the job number.
# The scope is the same as for Enter-BuildTask.
function Enter-BuildJob($Number) {
	equals $TaskName $Task.Name # the same scope
	'Enter job {1} of {0}' -f $TaskName, $Number
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	$$ = try {$Task = 1} catch {$_}
	assert ($$ -like $err)
}

# Exit-BuildJob is called after each script job. Its argument is the job number.
# The scope is the same as for Enter-BuildTask.
function Exit-BuildJob($Number) {
	equals $TaskName $Task.Name # the same scope
	'Exit job {1} of {0}' -f $TaskName, $Number
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
	$$ = try {$Task = 1} catch {$_}
	assert ($$ -like $err)
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
