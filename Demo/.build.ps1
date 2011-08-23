
<#
.Synopsis
	Example build script with a few use cases and tutorial comments.

.Description
	Build scripts can use parameters. They are passed in as the Parameters
	argument of Invoke-Build.

.Example
	# By convention the default task of this script is called just like:
	Invoke-Build
#>

param
(
	# This value is available for all tasks ($Param1).
	# Build script parameters often have default values.
	# Actual values are specified on Invoke-Build calls.
	# It can be changed by tasks ($script:Param1 = ...).
	$Param1 = "param 1"
)

# This value is available for all tasks ($Value1).
# Unlike parameters it is initialized internally.
# It can be changed by tasks ($script:Value1 = ...).
$Value1 = "value 1"

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
	"Param1='$Param1' Value1='$Value1'"

	# set parameters and values
	$script:Param1 = 'new param 1'
	$script:Value1 = 'new value 1'

	# create a new value to be used by `ParamsValues2`
	$script:NewValue1 = 42
}

# This task depends on another task ParamsValues1. Instead of having the
# Depends parameter (like psake does) tasks have the Jobs list. Each job is
# either an existing task name to be executed or a script block to be executed
# on behalf of this task. Tasks and blocks are invoked in the specified order.
task ParamsValues2 ParamsValues1, SharedValueTask1, {
	"In ParamsValues2"
	"Param1='$Param1' Value1='$Value1' NewValue1='$NewValue1' SharedValue1='$SharedValue1'"
}

# Just like regular scripts, build scripts may have functions used by tasks.
# For example, this function is used by several tasks testing various issues.
function Test-Issue([Parameter()]$Task, $Build, $ExpectedMessagePattern) {
	$message = ''
	try { Invoke-Build $Task $Build }
	catch { $message = "$_" }
	if ($message -notlike $ExpectedMessagePattern) {
		ThrowTerminatingError("Actual message: $message")
	}
	Out-Color Green "Issue '$Task' of '$Build' is tested."
}

# This task ensures that cyclic references are caught.
# Change the expected message and make the test to fail to see the task stack.
task CyclicReference {
	Test-Issue default CyclicReference.build.ps1 "Task 'task2': job 1: cyclic reference to 'task1'.*"
}

# This task ensures that tasks with the same name cannot be added twice.
task TaskAddedTwice {
	Test-Issue default TaskAddedTwice.build.ps1 "Task 'task1' is added twice:*1: *2: *"
}

# This task ensures that task jobs can be either strings or script blocks.
task TaskInvalidJob {
	# this fails
	Test-Issue default TaskInvalidJob.build.ps1 "Task 'default': job 3: invalid job type.*"

	# but this works because Invoke-Build checks only tasks to be invoked
	Test-Issue task1 TaskInvalidJob.build.ps1
}

# This task tests conditional tasks, see ConditionalTask.build.ps1
# It shows how to invoke a build script with parameters.
task ConditionalTask {
	# test Debug
	Invoke-Build default ConditionalTask.build.ps1 @{ Configuration = 'Debug' }
	# test Release
	Invoke-Build default ConditionalTask.build.ps1 @{ Configuration = 'Release' }
	# OK
	Out-Color Green "Conditional task is tested."
}

# This tasks tests Invoke-Exec (exec).
task ExecInvokeTool {
	# default works fine and makes tests there
	Invoke-Build default ExecTestCases.build.ps1

	# these builds fail, test them by Test-Issue
	Test-Issue ExecFailsCode13 ExecTestCases.build.ps1 'Validation script {*} returns false after {*}.'
	Test-Issue ExecFailsBadCommand ExecTestCases.build.ps1 'Bad Command.*'
	Test-Issue ExecFailsBadValidate ExecTestCases.build.ps1 'Bad Validate.*'
}

# Invoke-Build should expose only documented variables! If this test shows
# warnings about unknown variables (very likely) and they are presumably
# created by Invoke-Build (less likely), please let the author know.
task TestVariables {
	# get variables in a clean session
	$0 = PowerShell "Get-Variable | Select-Object -ExpandProperty Name"
	Get-Variable | .{process{
		if (($0 -notcontains $_.Name) -and ($_.Name.Length -ge 2)) {
			switch($_.Name) {
				# exposed by Invoke-Build
				'BuildFile' { 'BuildFile - build script file path' }
				'BuildRoot' { 'BuildRoot - build script root path' }
				'WhatIf' { 'WhatIf - Invoke-Build parameter' }
				# exposed but internal
				'BuildList' { 'BuildList - list of registered tasks' }
				'PSCmdlet' { 'PSCmdlet - core variable of a caller' }
				# build script data
				'NewValue1' { }
				'Param1' { }
				'SharedValue1' { }
				'Value1' { }
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
	CyclicReference,
	TaskAddedTwice,
	TaskInvalidJob,
	ConditionalTask,
	ExecInvokeTool,
	TestVariables

# This task calls all sample and the main test task.
# By convention it is the default task due to its name.
task default ParamsValues2, ParamsValues1, SharedTask2, {
	"In default, script 1"
},
# It is possible to have more than one script jobs.
{
	"In default, script 2"
	Invoke-Build SharedTask1 Shared.Tasks.ps1
},
# It is possible to have task jobs after script jobs.
Tests
