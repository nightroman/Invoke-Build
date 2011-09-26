
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
# PS> Invoke-Build ... { . <script> <parameters> }
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
# Note: assert is the predefined alias of Assert-BuildTrue.
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

# Test empty tasks. They are rare but possible.
task Dummy @()

# Test ? ~ show tasks
task Show {
	Invoke-Build ? Assert.build.ps1
}

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
function Test-Issue([Parameter()]$Task, $Script, $ExpectedMessagePattern) {
	$message = ''
	try { Invoke-Build $Task $Script }
	catch { $message = "$_" }
	if ($message -notlike $ExpectedMessagePattern) {
		Invoke-BuildError "Expected pattern: [`n$ExpectedMessagePattern`n]`n Actual message: [`n$message`n]"
	}
	"Issue '$Task' of '$Script' is tested."
}

# Test After and Before tasks.
task Alter {
	Invoke-Build . Alter.build.ps1
}

# Test assert.
task Assert {
	Invoke-Build . Assert.build.ps1
}

# Test conditional tasks.
# It shows how to invoke a build script with parameters (Debug|Release).
task ConditionalTasks {
	Invoke-Build . { . .\ConditionalTasks.build.ps1 Debug }
	Invoke-Build . { . .\ConditionalTasks.build.ps1 Release }
	Invoke-Build TestScriptCondition ConditionalTasks.build.ps1
}

# Test exec.
task Exec {
	Invoke-Build . Exec.build.ps1
}

# Test incremental tasks.
task Incremental {
	Invoke-Build . Incremental.build.ps1
}

# Test invalid tasks.
task InvalidTasks {
	Invoke-Build . InvalidTasks.build.ps1
}

# Tests property.
task Property {
	Invoke-Build . Property.build.ps1
}

# Test protected tasks (@{Task=1} notation).
task ProtectedTasks {
	Invoke-Build . ProtectedTasks.build.ps1
}

# Test use.
task Use {
	Invoke-Build . Use.build.ps1
}

# Test an empty build file.
task Empty {
	# no task is specified
	Test-Issue @() Empty.build.ps1 'There is no task in the script.'
	# a task is specified
	Test-Issue Missing Empty.build.ps1 "Task 'Missing' is not defined."
}

# Test runtime errors.
task ErrorCases {
	Test-Issue TestAlmostSurvives ErrorCases.build.ps1 'Error2'
	Test-Issue ScriptConditionFails ErrorCases.build.ps1 'If fails.'
	Test-Issue InputsFails ErrorCases.build.ps1 'Inputs fails.'
	Test-Issue OutputsFails ErrorCases.build.ps1 'Outputs fails.'
	Test-Issue InputsOutputsMismatch ErrorCases.build.ps1 "Task 'InputsOutputsMismatch': Different input and output counts: 1 and 0."
	Test-Issue MissingInputsItems ErrorCases.build.ps1 "Task 'MissingInputsItems': Error on resolving inputs: Cannot find path 'missing' because it does not exist."
	Test-Issue MissingProperty ErrorCases.build.ps1 "PowerShell or environment variable 'MissingProperty' is not defined."
}

# Test/cover the default parameter.
task TestDefaultParameter {
	Invoke-Build TestDefaultParameter ConditionalTasks.build.ps1
}

# Test exit codes on errors.
task TestExitCode {
	# continue on errors and use -NoProfile to ensure this, too
	$ErrorActionPreference = 'Continue'

	# missing file
	cmd /c PowerShell.exe -NoProfile Invoke-Build.ps1 Foo MissingFile
	assert ($LastExitCode -eq 1)

	# missing task
	cmd /c PowerShell.exe -NoProfile Invoke-Build.ps1 MissingTask Empty.build.ps1
	assert ($LastExitCode -eq 1)

	cmd /c PowerShell.exe -NoProfile Invoke-Build.ps1 AssertDefault Assert.build.ps1
	assert ($LastExitCode -eq 1)
}

# Test the Script parameter issues.
task TestScriptParameter {
	$var = '.\MissingScript.ps1'
	Test-Issue . {} "Invalid Script. The first token should be the . operator."
	Test-Issue . { . } "Invalid Script. The second token should be Command, String, or Variable. Actual type: NewLine."
	Test-Issue . { . 42 } "Invalid Script. The second token should be Command, String, or Variable. Actual type: Number."
	Test-Issue . { . .\MissingScript.ps1 } "Invalid Script. The term '.\MissingScript.ps1' is not recognized as *"
	Test-Issue . { . '.\MissingScript.ps1' } "Invalid Script. The term '.\MissingScript.ps1' is not recognized as *"
	Test-Issue . { . $var } "Invalid Script. The term '.\MissingScript.ps1' is not recognized as *"
}

# The task shows unwanted functions potentially introduced by Invoke-Build.
task TestFunctions {
	$list = PowerShell "Get-Command -CommandType Function | Select-Object -ExpandProperty Name"
	$list += 'Test-Issue'
	$exposed = @(
		'Add-BuildTask'
		'Assert-BuildTrue'
		'Get-BuildError'
		'Get-BuildProperty'
		'Get-BuildVersion'
		'Invoke-BuildError'
		'Invoke-BuildExec'
		'Use-BuildAlias'
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

# Invoke-Build should expose only documented variables. If this test shows
# warnings about unknown variables (very likely) and they are presumably
# created by Invoke-Build (less likely), please let the author know.
task TestVariables {
	# get variables in a clean session
	$0 = PowerShell "Get-Variable | Select-Object -ExpandProperty Name"
	$0 += @(
		'BuildData' # internal data
		'BuildInfo' # internal data
		'result' # for the caller
		# system
		'foreach'
		'LASTEXITCODE'
		'PSCmdlet'
		'this'
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

# This task calls all test tasks.
task Tests `
	Dummy,
	Show,
	Alter,
	Assert,
	ConditionalTasks,
	Empty,
	ErrorCases,
	Exec,
	Incremental,
	InvalidTasks,
	Property,
	ProtectedTasks,
	Use,
	TestDefaultParameter,
	TestExitCode,
	TestScriptParameter,
	TestFunctions,
	TestVariables

# Show all help.
task ShowHelp {
	@(
		'Invoke-Build'
		'Add-BuildTask'
		'Assert-BuildTrue'
		'Get-BuildError'
		'Get-BuildProperty'
		'Get-BuildVersion'
		'Invoke-BuildError'
		'Invoke-BuildExec'
		'Use-BuildAlias'
		'Write-BuildText'
	) | %{
		'#'*77
		Get-Help -Full $_
	} |
	Out-String -Width 80
}

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
ShowHelp
