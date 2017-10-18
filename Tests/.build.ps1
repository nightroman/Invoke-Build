
<#
.Synopsis
	Example/test build script with a few use cases and tutorial comments.

.Description
	This script invokes tests of typical use/problem cases. They are grouped by
	categories in other scripts in this directory. But this script shows a few
	points of interest as well.

	The build shows many errors and warnings because that is what it basically
	tests. But the build itself should not fail, all errors should be caught.

.Example
	Invoke-Build
	Assuming Invoke-Build.ps1 is in the system path and the current location is
	the Tests directory this command invokes the . task from this build script.
#>

# Build scripts can use parameters
# PS> Invoke-Build ... -MyParam1 ...
param(
	# This value is available for all tasks ($MyParam1).
	# Build script parameters often have default values.
	# Actual values are specified on Invoke-Build calls.
	# Values can be changed by tasks ($script:MyParam1 = ...).
	$MyParam1 = "param 1"
)

# This value is available for all tasks ($MyValue1).
# Unlike parameters it is initialized in the script only.
# Values can be changed by tasks ($script:MyValue1 = ...).
$MyValue1 = "value 1"

# Invoke-Build exposes $BuildFile and $BuildRoot. Test them.
# Note: assert is the predefined alias of Assert-Build.
$MyPath = $MyInvocation.MyCommand.Path
equals $MyPath $BuildFile
equals (Split-Path $MyPath) $BuildRoot

# In order to import more tasks invoke the script containing them. *.tasks.ps1
# files play the same role as MSBuild *.targets files. NOTE: It is not typical
# but imported tasks may use parameters and values as well. In this case task
# scripts should be dot-sourced.
.\Shared.tasks.ps1

# $WhatIf is used in order to skip some code in cases like getting tasks.
if (!$WhatIf) {
	# Warnings are shown together with errors in the build summary.
	Write-Warning 'Ignore this warning.'
}

# Synopsis: -WhatIf is used in order to show task scripts without invoking them.
# Note: -Result can be used in order to get some information as well.
# But this information is not always the same as without -WhatIf.
task WhatIf {
	Invoke-Build . Conditional.build.ps1 -WhatIf -Result Result -Configuration Debug
	equals $Result.Tasks.Count 1
}

# Synopsis: "Invoke-Build ?[?]" lists tasks.
# 1) show tasks with brief information
# 2) get task as an ordered dictionary
task ListTask {
	# show tasks info
	($r = Invoke-Build ? Assert.test.ps1)
	equals $r.Count 3
	equals $r[0].Name AssertDefault
	equals $r[0].Jobs '{}'
	equals $r[0].Synopsis 'Fail with the default message.'
	equals $r[2].Name .
	equals ($r[2].Jobs -join ', ') 'AssertDefault, AssertMessage, {}'
	equals $r[2].Synopsis 'Call tests and check errors.'

	# get task objects
	$all = Invoke-Build ?? Assert.test.ps1
	equals $all.Count 3
}

# Synopsis: Null Jobs, rare but possible.
task Dummy1

# Synopsis: Empty Jobs, rare but possible.
task Dummy2 @()

# Synopsis: Script parameters and values are standard variables in the script scope.
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

# Synopsis: References the task ParamsValues1 and then invokes its own script.
# Referenced tasks and actions are specified by the parameter Job. Any number
# and any order of jobs is allowed. Referenced tasks often go before actions
# but references are allowed after and between actions as well.
task ParamsValues2 ParamsValues1, {
	"In ParamsValues2"
	"MyParam1='$MyParam1' MyValue1='$MyValue1' MyNewValue1='$MyNewValue1'"
}

# Synopsis: Invoke all tasks in all *.test.ps1 scripts using the special task **.
# (Another special task * is used to invoke all tasks in one build file).
task AllTestScripts {
	# ** invokes all *.test.ps1
	Invoke-Build ** -Result Result

	# Result can be used with **
	assert ($Result.Tasks.Count -gt 0)
}

# Synopsis: Test persistent builds.
task Checkpoint {
	Invoke-Build test Checkpoint.build.ps1
}

# Synopsis: Test conditional tasks.
# It also shows how to invoke build scripts with parameters.
task Conditional {
	# call with Debug, using the dynamic parameter
	Invoke-Build . Conditional.build.ps1 -Configuration Debug
	# call with Release, using splatting
	$param = @{Configuration = 'Release'}
	Invoke-Build . Conditional.build.ps1 @param
	# call default (! there was an issue !) and also test errors
	Invoke-Build TestScriptCondition, ConditionalErrors Conditional.build.ps1
}

# Synopsis: Test dynamic tasks (and some issues).
task Dynamic {
	# first, just request the task list and test it
	$all = Invoke-Build ?? Dynamic.build.ps1
	equals $all.Count 5
	$last = $all.Item(4)
	equals $last.Name '.'
	equals $last.Jobs.Count 4

	# invoke with results and test: 5 tasks are done
	Invoke-Build . Dynamic.build.ps1 -Result result
	equals $result.Tasks.Count 5
}

# Synopsis: Test the default parameter.
task TestDefaultParameter {
	Invoke-Build TestDefaultParameter Conditional.build.ps1
}

# Synopsis: Test exit codes on errors.
task TestExitCode {
	# continue on errors and use -NoProfile to ensure this, too
	$ErrorActionPreference = 'Continue'

	# missing file
	Invoke-PowerShell -NoProfile -Command Invoke-Build.ps1 Foo MissingFile
	equals $LastExitCode 1

	# missing task
	Invoke-PowerShell -NoProfile -Command Invoke-Build.ps1 MissingTask Dynamic.build.ps1
	equals $LastExitCode 1

	Invoke-PowerShell -NoProfile -Command Invoke-Build.ps1 AssertDefault Assert.test.ps1
	equals $LastExitCode 1
}

# Synopsis: Test alias Invoke-Build and more.
# In a new (!) session set ${*}, build, check for the alias. It also covers
# work around "Default Host" exception on setting colors and the case with
# null $BuildFile.
task TestSelfAlias {
	$script = {
		${*} = 42
		Invoke-Build . {
			task . {
				# null?
				equals $BuildFile
				# defined?
				(Get-Alias Invoke-Build -ErrorAction Stop).Definition
			}
		}
		# two errors on setting ForegroundColor
		foreach($_ in $Error) {"$_"}
	}

	($log = [PowerShell]::Create().AddScript($script).Invoke() | Out-String)
	assert $log.Contains('Build succeeded')
}

# Synopsis: Test a build invoked from a background job just to be sure it works.
task TestStartJob {
    $job = Start-Job { Invoke-Build . $args[0] } -ArgumentList "$BuildRoot\Dynamic.build.ps1"
    $log = Wait-Job $job | Receive-Job
    Remove-Job $job
    $log
    assert ($log[-1].StartsWith('Build succeeded. 5 tasks'))
}

# Synopsis: Invoke-Build should expose only documented functions.
# The test warns about unknowns. In a clean session there must be no warnings.
task TestFunctions {
	$list = [PowerShell]::Create().AddScript({ Get-Command -CommandType Function | Select-Object -ExpandProperty Name }).Invoke()
	$list += 'Format-Error', 'Test-Error', 'Test-Issue'
	$known = @(
		# build script and tests
		'Invoke-MyModuleStuff'
		# engine tools
		'Add-BuildTask'
		'Assert-Build'
		'Assert-BuildEquals'
		'Enter-Build'
		'Enter-BuildJob'
		'Enter-BuildTask'
		'Exit-Build'
		'Exit-BuildJob'
		'Exit-BuildTask'
		'Export-Build'
		'Get-BuildError'
		'Get-BuildFile'
		'Get-BuildProperty'
		'Get-BuildSynopsis'
		'Import-Build'
		'Invoke-BuildExec'
		'New-BuildJob'
		'Set-BuildHeader'
		'Test-BuildAsset'
		'Use-BuildAlias'
		'Write-Build'
		'Write-Warning'
	)
	Get-Command -CommandType Function | .{process{
		if (($list -notcontains $_.Name) -and ($_.Name[0] -ne '*')) {
			if ($known -notcontains $_.Name) {
				Write-Warning "Unknown function '$_'."
			}
		}
	}}
}

# Synopsis: Invoke-Build should expose only documented variables.
# The test warns about unknowns. In a clean session there must be no warnings.
task TestVariables {
	$MyKnown = [PowerShell]::Create().AddScript({ Get-Variable | Select-Object -ExpandProperty Name }).Invoke()
	$MyKnown += @(
		# exposed by the project script
		'Result'
		'NoTestDiff'
		# system variables
		'_'
		'foreach'
		'LASTEXITCODE'
		'PROFILE'
		'PSCmdlet'
		'PSItem'
		'PWD'
		'this'
	)
	Get-Variable | .{process{
		if (($MyKnown -notcontains $_.Name) -and ($_.Name -notlike 'My*')) {
			switch($_.Name) {
				# exposed by Invoke-Build
				'*' { '* - internal build data' }
				'BuildFile' { 'BuildFile - build script path - ' + $BuildFile }
				'BuildRoot' { 'BuildRoot - build script root - ' + $BuildRoot }
				'BuildTask' { 'BuildTask - initial task list - ' + $BuildTask }
				'Task' { 'Task - the current task' }
				'WhatIf' { 'WhatIf - Invoke-Build parameter' }
				default { Write-Warning "Unknown variable '$_'." }
			}
		}
	}}
}

# Synopsis: Show full help.
task ShowHelp {
	@(
		'Invoke-Build'
		'Invoke-Builds'
		'Add-BuildTask'
		'Assert-Build'
		'Assert-BuildEquals'
		'Get-BuildError'
		'Get-BuildProperty'
		'Get-BuildSynopsis'
		'Invoke-BuildExec'
		'Resolve-MSBuild'
		'Test-BuildAsset'
		'Use-BuildAlias'
		'Write-Build'
	) | .{process{
		'#'*77
		Get-Help -Full $_
	}} |
	Out-String -Width 80
}

# Synopsis: This task calls all test tasks.
task Tests `
Dummy1,
Dummy2,
AllTestScripts,
Checkpoint,
Conditional,
Dynamic,
TestDefaultParameter,
TestExitCode,
TestSelfAlias,
TestStartJob,
TestFunctions,
TestVariables

# Synopsis: This is the default task due to its name, by the convention.
# This task calls all the samples and the main test task.
task . ParamsValues2, ParamsValues1, SharedTask2, {
	"In default, script 1"
},
# It is possible to have several script jobs.
{
	"In default, script 2"
	Invoke-Build SharedTask1 Shared.tasks.ps1
},
# Tasks can be referenced between or after script jobs.
Tests,
WhatIf,
ListTask,
ShowHelp
