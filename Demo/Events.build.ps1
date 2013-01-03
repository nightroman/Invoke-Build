
<#
.Synopsis
	Demo of event functions.

.Description
	The tasks and events of this script sets a noise location and check that on
	calling the location is restored to $BuildRoot.

.Example
	Invoke-Build . Events.build.ps1
#>

Set-Location $HOME

# Enter-Build is called before the first task in the script scope. Its local
# variables become available for all tasks and other event functions.
function Enter-Build {
	"Enter build"
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
	Set-Location $HOME
}

# Exit-Build is called after the last task or on build failures.
function Exit-Build {
	"Exit build"
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
	Set-Location $HOME
}

# Enter-BuildTask is called before each task. It takes one argument - the task.
# The scope is new, the parent for the task script jobs.
function Enter-BuildTask($Task) {
	'Enter task {0}' -f $Task.Name
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
	Set-Location $HOME
}

# Exit-BuildTask is called after each task. Arguments and the scope are the
# same as for Enter-BuildTask.
function Exit-BuildTask($Task) {
	'Exit task {0}' -f $Task.Name
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
	Set-Location $HOME
}

# Enter-BuildJob is called before each script job. It takes two arguments - the
# task and the job number. The scope is the same as for Enter-BuildTask.
function Enter-BuildJob($Task, $Number) {
	'Enter job {1} of {0}' -f $Task.Name, $Number
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
	Set-Location $HOME
}

# Exit-BuildJob is called after each script job. Arguments and the scope are
# the same as for Enter-BuildJob.
function Exit-BuildJob($Task, $Number) {
	'Exit job {1} of {0}' -f $Task.Name, $Number
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
	Set-Location $HOME
}

task Task1 {
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
	Set-Location $HOME
}

task Task2 Task1, {
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
	Set-Location $HOME
}

task . Task2
