
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
	the Demo directory this command invokes the . task from this build script.
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
# Unlike parameters it is initialized in the script only.
# Values can be changed by tasks ($script:MyValue1 = ...).
$MyValue1 = "value 1"

# Invoke-Build exposes $BuildFile and $BuildRoot. Test them.
# Note: assert is the predefined alias of Assert-Build.
$MyPath = $MyInvocation.MyCommand.Path
assert ($MyPath -eq $BuildFile)
assert ((Split-Path $MyPath) -eq $BuildRoot)

# In order to import more tasks invoke the script containing them. *.tasks.ps1
# files play the same role as MSBuild *.targets files. NOTE: It is not typical
# but imported tasks may use parameters and values as well. In this case task
# scripts should be dot-sourced.
.\Shared.tasks.ps1

# Warning. Warnings are shown together with errors in the build summary.
Write-Warning "Ignore this warning."

# -WhatIf is used in order to show task scripts without invoking them.
# Note: -Result can be used in order to get some information as well.
# But this information is not always the same as without -WhatIf.
task WhatIf {
	Invoke-Build . Conditional.build.ps1 @{Configuration='Debug'} -WhatIf -Result Result
	assert ($Result.Tasks.Count -eq 1)
}

# "Invoke-Build ?" lists tasks:
# 1) show tasks with brief information (just ?);
# 2) get task list (use ? with the parameter Result).
# The Wrapper.test.ps1 uses ? and Result in order to show detailed task trees.
task ListTask {
	# show tasks
	$r = Invoke-Build ? Assert.test.ps1
	$r
	assert ($r.Count -eq 3)
	assert ($r[0] -match '\(\d+\): AssertDefault$')
	assert ($r[2] -match '\(\d+\): \.$')

	# get task list
	$all = Invoke-Build ?? Assert.test.ps1
	assert ($all.Count -eq 3)
}

# ". Invoke-Build" is used in order to load exposed functions and use Get-Help.
# This command itself shows the current version and function help summary.
task ShowInfo {
	. Invoke-Build
}

# Tasks with null or empty job lists are rare but possible.
task Dummy1
task Dummy2 @()

# Script parameters and values are standard variables in the script scope.
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

# This task invokes (references) the task ParamsValues1 and then invokes its
# own script. Referenced tasks and own scripts are specified by the parameter
# Job. Any number and any order of jobs is allowed. Referenced tasks often go
# before own scripts but tasks are allowed after and between scripts as well.
task ParamsValues2 ParamsValues1, {
	"In ParamsValues2"
	"MyParam1='$MyParam1' MyValue1='$MyValue1' MyNewValue1='$MyNewValue1'"
}

# Invoke all tasks in all *.test.ps1 scripts using the special task **.
# (Another special task * is used to invoke all tasks in one build file).
task AllTestScripts {
	# ** invokes all *.test.ps1
	Invoke-Build ** -Result Result

	# Result can be used with **
	assert ($Result.Tasks.Count -gt 0)
}

# Test persistent builds.
task Checkpoint {
	Invoke-Build test Checkpoint.build.ps1
}

# Test conditional tasks.
# It also shows how to invoke build scripts with parameters.
task Conditional {
	# call with Debug
	Invoke-Build . Conditional.build.ps1 @{ Configuration = 'Debug' }
	# call with Release
	Invoke-Build . Conditional.build.ps1 @{ Configuration = 'Release' }
	# call default (! there was an issue !) and also test errors
	Invoke-Build TestScriptCondition, ConditionalErrors Conditional.build.ps1
}

# Test dynamic tasks (and other issues).
task Dynamic {
	# first, just request the task list and test it
	$all = Invoke-Build ?? Dynamic.build.ps1
	assert ($all.Count -eq 5)
	$last = $all.Item(4)
	assert ($last.Name -eq '.')
	assert ($last.Job.Count -eq 4)

	# invoke with results and test: 5 tasks are done
	Invoke-Build . Dynamic.build.ps1 -Result result
	assert ($result.Tasks.Count -eq 5)
}

# Test incremental and partial incremental tasks.
task Incremental {
	Invoke-Build . Incremental.build.ps1
}

# Test the default parameter.
task TestDefaultParameter {
	Invoke-Build TestDefaultParameter Conditional.build.ps1
}

# Test exit codes on errors.
task TestExitCode {
	# continue on errors and use -NoProfile to ensure this, too
	$ErrorActionPreference = 'Continue'

	# missing file
	cmd /c PowerShell.exe -NoProfile Invoke-Build.ps1 Foo MissingFile
	assert ($LastExitCode -eq 1)

	# missing task
	cmd /c PowerShell.exe -NoProfile Invoke-Build.ps1 MissingTask Dynamic.build.ps1
	assert ($LastExitCode -eq 1)

	cmd /c PowerShell.exe -NoProfile Invoke-Build.ps1 AssertDefault Assert.test.ps1
	assert ($LastExitCode -eq 1)
}

# Test the internally defined alias Invoke-Build. It is strongly recommended
# for nested calls instead of the script name Invoke-Build.ps1. In a new (!)
# session set ${*}, build, check for the alias. It also covers work around
# "Default Host" exception on setting colors.
task TestSelfAlias {
    'task . { (Get-Alias Invoke-Build -ea Stop).Definition }' > z.build.ps1
    $log = [PowerShell]::Create().AddScript("`${*} = 42; Invoke-Build . '$BuildRoot\z.build.ps1'").Invoke() | Out-String
    $log
    assert ($log.Contains('Build succeeded'))
    Remove-Item z.build.ps1
}

# Test a build invoked from a background job just to be sure it works.
task TestStartJob {
    $job = Start-Job { Invoke-Build . $args[0] } -ArgumentList "$BuildRoot\Dynamic.build.ps1"
    $log = Wait-Job $job | Receive-Job
    Remove-Job $job
    $log
    assert ($log[-1].StartsWith('Build succeeded. 5 tasks'))
}

# Test/show "unexpected" functions.
task TestFunctions {
	$list = [PowerShell]::Create().AddScript({ Get-Command -CommandType Function | Select-Object -ExpandProperty Name }).Invoke()
	$list += 'Format-Error', 'Test-Error', 'Test-Issue'
	$exposed = @(
		'Add-BuildTask'
		'Assert-Build'
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
		'Get-BuildVersion'
		'Import-Build'
		'Invoke-BuildExec'
		'New-BuildJob'
		'Use-BuildAlias'
		'Write-Build'
		'Write-Warning'
	)
	Get-Command -CommandType Function | .{process{
		if (($list -notcontains $_.Name) -and ($_.Name[0] -ne '*')) {
			if ($exposed -contains $_.Name) {
				"Function $($_.Name) is from Invoke-Build."
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
	$0 = [PowerShell]::Create().AddScript({ Get-Variable | Select-Object -ExpandProperty Name }).Invoke()
	$0 += @(
		# project build script
		'Result'
		'SkipTestDiff'
		# system variables
		'foreach'
		'LASTEXITCODE'
		'PROFILE'
		'PSCmdlet'
		'PSItem'
		'PWD'
		'this'
	)
	Get-Variable | .{process{
		if (($0 -notcontains $_.Name) -and ($_.Name.Length -ge 2) -and ($_.Name -notmatch '^(\*|My)')) {
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

# Show full help.
task ShowHelp {
	@(
		'Invoke-Build'
		'Invoke-Builds'
		'Add-BuildTask'
		'Assert-Build'
		'Get-BuildError'
		'Get-BuildProperty'
		'Get-BuildVersion'
		'Invoke-BuildExec'
		'Use-BuildAlias'
		'Write-Build'
	) | %{
		'#'*77
		Get-Help -Full $_
	} |
	Out-String -Width 80
}

# This task calls all test tasks.
task Tests `
Dummy1,
Dummy2,
AllTestScripts,
Checkpoint,
Conditional,
Dynamic,
Incremental,
TestDefaultParameter,
TestExitCode,
TestSelfAlias,
TestStartJob,
TestFunctions,
TestVariables

# This is the default task due to its name, by the convention.
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
ShowHelp,
ShowInfo
