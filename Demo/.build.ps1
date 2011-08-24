
<#
.Synopsis
	Example build script with a few use cases and tutorial comments.

.Description
	Build scripts can use parameters. They are passed in as the Parameters
	argument of Invoke-Build.

.Example
	# By conventions the default . task of this script is called just like:
	Invoke-Build

.Link
	Invoke-Build
#>

param
(
	# This value is available for all tasks ($MyParam1).
	# Build script parameters often have default values.
	# Actual values are specified on Invoke-Build calls.
	# It can be changed by tasks ($script:MyParam1 = ...).
	$MyParam1 = "param 1"
)

# This value is available for all tasks ($MyValue1).
# Unlike parameters it is initialized internally.
# It can be changed by tasks ($script:MyValue1 = ...).
$MyValue1 = "value 1"

# Invoke-Build exposes $BuildFile and $BuildRoot. Test them.
# Note: assert is the predefined alias of Assert-True.
$MyPath = $MyInvocation.MyCommand.Path
assert ($MyPath -eq $BuildFile)
assert ((Split-Path $MyPath) -eq $BuildRoot)

# In order to import more tasks invoke the script containing them.
# *.tasks.ps1 files play the same role as MSBuild *.targets files.
.\Shared.tasks.ps1

# It is not typical but imported tasks may have parameters and values
# as well. In this case the *.tasks.ps1 script has to be dot-sourced.
# Mind potential variable name conflicts in the same script scope!
. .\Values.tasks.ps1

# Parameters and values are just variables in the script scope.
# Read them as $Variable. Write them as $script:Variable = ...
task ParamsValues1 {
	"In ParamsValues1"

	# get parameters and values
	"MyParam1='$MyParam1' MyValue1='$MyValue1'"

	# set parameters and values
	$script:MyParam1 = 'new param 1'
	$script:MyValue1 = 'new value 1'

	# create a new value to be used by `ParamsValues2`
	$script:MyNewValue1 = 42
}

# This task depends on another task ParamsValues1. Instead of having the
# Depends parameter (like psake does) tasks have the Jobs list. Each job is
# either an existing task name to be executed or a script block to be executed
# on behalf of this task. Tasks and blocks are invoked in the specified order.
task ParamsValues2 ParamsValues1, SharedValueTask1, {
	"In ParamsValues2"
	"MyParam1='$MyParam1' MyValue1='$MyValue1' MyNewValue1='$MyNewValue1' MySharedValue1='$MySharedValue1'"
}

# Just like regular scripts, build scripts may have functions used by tasks.
# For example, this function is used by several tasks testing various issues.
function Test-Issue([Parameter()]$Task, $Build, $ExpectedMessagePattern) {
	$message = ''
	try { Invoke-Build $Task $Build }
	catch { $message = "$_" }
	if ($message -notlike $ExpectedMessagePattern) {
		ThrowTerminatingError("Actual message: [`n$message`n]")
	}
	"Issue '$Task' of '$Build' is tested."
}

# This task calls tests of Assert-True (assert).
task Assert-True {
	Invoke-Build . Assert-True.build.ps1
}

# This task tests conditional tasks, see ConditionalTask.build.ps1
# It shows how to invoke a build script with parameters (Debug|Release).
task ConditionalTask {
	Invoke-Build . ConditionalTask.build.ps1 @{ Configuration = 'Debug' }
	Invoke-Build . ConditionalTask.build.ps1 @{ Configuration = 'Release' }
}

# This task ensures that cyclic references are caught.
# Change the expected message and make the test to fail to see the task stack.
task CyclicReference {
	Test-Issue . CyclicReference.build.ps1 "Task 'task2': job 1: cyclic reference to 'task1'.*"
}

# This task calls Invoke-Exec (exec) tests.
task Invoke-Exec {
	Invoke-Build . Invoke-Exec.build.ps1
}

# This task ensures that tasks with the same name cannot be added twice.
task TaskAddedTwice {
	Test-Issue . TaskAddedTwice.build.ps1 "Task 'task1' is added twice:*1: *2: *"
}

# This task ensures that task jobs can be either strings or script blocks.
task TaskInvalidJob {
	# this fails
	Test-Issue . TaskInvalidJob.build.ps1 "Task '.': job 4: invalid job type.*"

	# but this works because Invoke-Build checks only tasks to be invoked
	Test-Issue task1 TaskInvalidJob.build.ps1
}

# This task ensures that missing tasks are caught.
task TaskNotDefined {
	Test-Issue . TaskNotDefined.build.ps1 "Task 'task1': job 1: task 'missing' is not defined.*"
}

# This task tests job tasks using @{Name=1} notation.
task TryTasks {
	Invoke-Build . TryTasks.build.ps1
}

# This task calls tests in Use-Framework.build.ps1
task Use-Framework {
	Invoke-Build . Use-Framework.build.ps1
}

# Invoke-Build should expose only documented variables! If this test shows
# warnings about unknown variables (very likely) and they are presumably
# created by Invoke-Build (less likely), please let the author know.
task TestVariables {
	# get variables in a clean session
	$0 = PowerShell "Get-Variable | Select-Object -ExpandProperty Name"
	Get-Variable | .{process{
		if (($0 -notcontains $_.Name) -and ($_.Name.Length -ge 2) -and ($_.Name -notlike 'My*')) {
			switch($_.Name) {
				# exposed by Invoke-Build
				'BuildFile' { 'BuildFile - build script file path - ' + $BuildFile}
				'BuildRoot' { 'BuildRoot - build script root path - ' + $BuildRoot }
				'WhatIf' { 'WhatIf - Invoke-Build parameter' }
				# exposed but internal
				'BuildInfo' { 'BuildInfo - internal data' }
				'BuildThis' { 'BuildThis - internal data' }
				'PSCmdlet' { 'PSCmdlet - system variable' }
				# some system data
				'foreach' { }
				'LASTEXITCODE' { }
				default { Write-Warning "Unknown variable '$_'." }
			}
		}
	}}
}

# This task calls all test tasks.
task Tests `
	Assert-True,
	ConditionalTask,
	CyclicReference,
	Invoke-Exec,
	TaskAddedTwice,
	TaskInvalidJob,
	TaskNotDefined,
	TryTasks,
	Use-Framework,
	TestVariables

# This task calls all sample and the main test task.
# By conventions it is the default task due to its name.
task . ParamsValues2, ParamsValues1, SharedTask2, {
	"In default, script 1"
},
# It is possible to have more than one script jobs.
{
	"In default, script 2"
	Invoke-Build SharedTask1 Shared.Tasks.ps1
},
# Tasks can be referenced between or after scripts.
Tests
