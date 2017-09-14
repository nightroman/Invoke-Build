
<#
.Synopsis
	Tests build events.

.Description
	The tasks and events of this script set a noise location and check that on
	calling the current location is restored to $BuildRoot.

	Task and job event scopes must be the same for a task.

.Example
	Invoke-Build * Events.test.ps1
#>

Set-Location $HOME

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
}

# Exit-BuildTask is called after each task.
# The scope is the same as for Enter-BuildTask.
Exit-BuildTask {
	equals $TaskName $Task.Name # the same scope
	'Exit task {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
}

# Enter-BuildJob is called before each action.
# The scope is the same as for Enter-BuildTask.
Enter-BuildJob {
	equals $TaskName $Task.Name # the same scope
	'Enter job {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
}

# Exit-BuildJob is called after each script job.
# The scope is the same as for Enter-BuildTask.
Exit-BuildJob {
	equals $TaskName $Task.Name # the same scope
	'Exit job {0}' -f $TaskName
	equals $BuildRoot (Get-Location).ProviderPath
	Set-Location $HOME
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
task RefTask2WithLowerCase task2

#! #66 define events before "?" processing
task HelpTaskAndEvents {
	# new session, are not defined by parents
	$null = exec {Invoke-PowerShell -NoProfile -Command Invoke-Build ? $BuildFile}
}

# #66 changes; ideally, need to test each but they are similar
task InvalidEvents {
	# invalid parameter type
	($r = try {<##> Enter-Build 42} catch {$_})
	assert (($r | Out-String) -like '*<##>*FullyQualifiedErrorId : ParameterArgumentTransformationError,Enter-Build*')

	# invalid parameter number
	($r = try {<##> Enter-Build {} 42} catch {$_})
	assert (($r | Out-String) -like '*<##>*FullyQualifiedErrorId : PositionalParameterNotFound,Enter-Build*')
}

# If a task fails then its $Task.Error is available in Exit-BuildJob.
task FailedTaskErrorInExitBuildJob {
	$file = {
		Exit-BuildJob {
			assert $Task.Error
		}
		task . {
			throw 42
		}
	}
	($r = try {Invoke-Build . $file} catch {$_})
	equals $r[-1].FullyQualifiedErrorId '42'
}

# Task and job events cannot assign the constant variable $Task.
task CannotAssignTaskInEvents {
	$file = {
		function Assert-CannotSetTask {
			($r = try {$Task = 1} catch {$_})
			equals $r.FullyQualifiedErrorId VariableNotWritable
		}
		Enter-BuildTask {
			'Enter-BuildTask'
			. Assert-CannotSetTask
		}
		Exit-BuildTask {
			'Exit-BuildTask'
			. Assert-CannotSetTask
		}
		Enter-BuildJob {
			'Enter-BuildJob'
			. Assert-CannotSetTask
		}
		Exit-BuildJob {
			'Exit-BuildJob'
			. Assert-CannotSetTask
		}
		task . {}
	}
	Invoke-Build . $file
}
