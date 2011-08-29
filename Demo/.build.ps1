
<#
.Synopsis
	Example/test build script with a few use cases and tutorial comments.

.Description
	This build script invokes tests of typical use/problem cases. Most of them
	are grouped by categories in the *.build.ps1 files in this directory. But
	this script shows a few points of interest as well.

	The build shows many errors and warnings because that is what it basically
	tests. But the build itself should not fail, all errors should be caught.

.Example
	Invoke-Build
	Assuming Invoke-Build.ps1 is in the system path and the current location is
	the Demo directory this command invokes the . task from this build script.

.Link
	Invoke-Build.ps1
#>

# Build scripts can use parameters passed in as
# PS> Invoke-Build ... -Parameters @{...}
param
(
	# This value is available for all tasks ($MyParam1).
	# Build script parameters often have default values.
	# Actual values are specified on Invoke-Build calls.
	# Values can be changed by tasks ($script:MyParam1 = ...).
	$MyParam1 = "param 1"
)

# This value is available for all tasks ($MyValue1).
# Unlike parameters it is initialized internally.
# Values can be changed by tasks ($script:MyValue1 = ...).
$MyValue1 = "value 1"

# Invoke-Build exposes $BuildFile and $BuildRoot. Test them.
# Note: assert is the predefined alias of Assert-True.
$MyPath = $MyInvocation.MyCommand.Path
assert ($MyPath -eq $BuildFile)
assert ((Split-Path $MyPath) -eq $BuildRoot)

# In order to import more tasks invoke the script containing them.
# *.tasks.ps1 files play the same role as MSBuild *.targets files.
.\SharedTasks.tasks.ps1

# It is not typical but imported tasks may have parameters and values
# as well. In this case the *.tasks.ps1 script has to be dot-sourced.
# Mind potential variable name conflicts in the same script scope!
. .\SharedTasksData.tasks.ps1

# Test warning
Write-Warning "Ignore this warning."

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
function Test-Issue([Parameter()]$Task, $Build, $ExpectedMessagePattern, $Parameters = @{}) {
	$message = ''
	try { Invoke-Build $Task $Build $Parameters }
	catch { $message = "$_" }
	if ($message -notlike $ExpectedMessagePattern) {
		Invoke-BuildError "Expected pattern: [`n$ExpectedMessagePattern`n]`n Actual message: [`n$message`n]"
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

# This task calls Invoke-BuildExec (exec) tests.
task Invoke-Exec {
	Invoke-Build . Invoke-Exec.build.ps1
}

# This task ensures that tasks with the same name cannot be added twice.
task TaskAddedTwice {
	Test-Issue . TaskAddedTwice.build.ps1 "Task 'task1' is added twice:*1: *2: *"
}

# This task ensures that task jobs can be either strings or script blocks.
task TaskInvalidJob {
	Test-Issue InvalidJobType TaskInvalidJob.build.ps1 "Task 'InvalidJobType': Job 4/4: Invalid job type." @{Test = 'InvalidJobType'}
	Test-Issue InvalidJobValue TaskInvalidJob.build.ps1 "Task 'InvalidJobValue': Job 1/1: Hashtable should have one item." @{Test = 'InvalidJobValue'}
}

# This task ensures that missing tasks are caught.
task TaskNotDefined {
	Test-Issue . TaskNotDefined.build.ps1 "Task 'task1': job 1: task 'missing' is not defined.*"
}

# This task tests job tasks using @{Name=1} notation.
task TryTasks {
	Invoke-Build . TryTasks.build.ps1
}

# This task also tests @{Name=1}, some subtle cases.
task TryTasksFails {
	Test-Issue . TryTasksFails.build.ps1 'Error2'
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
	$0 += @(
		'BuildInfo' # internal data
		'BuildThis' # internal data
		# system
		'foreach'
		'LASTEXITCODE'
		'PSCmdlet'
	)
	Get-Variable | .{process{
		if (($0 -notcontains $_.Name) -and ($_.Name.Length -ge 2) -and ($_.Name -notlike 'My*')) {
			switch($_.Name) {
				# exposed by Invoke-Build
				'BuildTask' { 'BuildTask - build task name list' }
				'BuildFile' { 'BuildFile - build script file path - ' + $BuildFile}
				'BuildRoot' { 'BuildRoot - build script root path - ' + $BuildRoot }
				'WhatIf' { 'WhatIf - Invoke-Build parameter' }
				default { Write-Warning "Unknown variable '$_'." }
			}
		}
	}}
}

# The task shows unwanted functions potentially introduced by Invoke-Build.
task TestFunctions {
	$list = PowerShell "Get-Command -CommandType Function | Select-Object -ExpandProperty Name"
	$list += 'Test-Issue'
	$exposed = @(
		'Add-BuildTask'
		'Assert-BuildTrue'
		'Get-BuildError'
		'Get-BuildVersion'
		'Invoke-BuildError'
		'Invoke-BuildExec'
		'Start-Build'
		'Use-BuildFramework'
		'Write-BuildText'
		'Write-Warning'
	)
	Get-Command -CommandType Function | .{process{
		if (($list -notcontains $_.Name) -and ($_.Name -notlike 'Invoke-Build-*')) {
			if ($exposed -contains $_.Name) {
				"Function $($_.Name) is one of Invoke-Build."
			}
			else {
				Write-Warning "Unknown function '$_'."
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
	TryTasksFails,
	Use-Framework,
	TestFunctions,
	TestVariables

# This task calls all sample and the main test task.
# By conventions it is the default task due to its name.
task . ParamsValues2, ParamsValues1, SharedTask2, {
	"In default, script 1"
},
# It is possible to have more than one script jobs.
{
	"In default, script 2"
	Invoke-Build SharedTask1 SharedTasks.tasks.ps1
},
# Tasks can be referenced between or after scripts.
Tests,
# The last test tests not yet documented data
{
	# This build statistics
	assert ($BuildThis.TaskCount -eq 19)
	assert ($BuildThis.ErrorCount -eq 0)
	assert ($BuildThis.WarningCount -ge 1)

	# Cumulative build statistics
	assert ($BuildInfo.TaskCount -ge $BuildThis.TaskCount)
	assert ($BuildInfo.ErrorCount -ge $BuildThis.ErrorCount)
	assert ($BuildInfo.WarningCount -ge $BuildThis.WarningCount)
}
