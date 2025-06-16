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
	> Invoke-Build
	Assuming the current location is Tests.
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

# This block is called before the first task.
Enter-Build {
	# dot-source common functions, import modules, etc.
	Import-Module .\Tools

	# show the version, note: Enter-Build may output, not script
	"PowerShell version: $($PSVersionTable.PSVersion)"

	# configure test environment
	if ($env:GITHUB_ACTION) {
		# add root to the path, as in the author setup
		$env:Path = "$(Split-Path $BuildRoot);$env:Path"
	}

	# Warnings are shown as usual and also after tasks.
	Write-Warning 'Ignore this warning.'
}

# Set custom task headers.
Set-BuildHeader { Write-Build 11 "Task $($args[0]) *".PadRight(79, '*') }

# Synopsis: "Invoke-Build ?[?]" info tasks.
# 1) show tasks with brief information
# 2) get tasks as ordered dictionary
task InfoTasks {
	# show tasks info
	$r = Invoke-Build ? Assert.test.ps1
	$r | Out-String

	equals $r.Count 3
	equals $r[0].Name AssertDefault
	equals $r[0].Jobs '{}'
	equals $r[0].Synopsis 'Fail with the default message.'
	equals $r[2].Name SafeTest
	equals ($r[2].Jobs -join ', ') '?AssertDefault, ?AssertMessage, {}'
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
# NB We can invoke all tests by one command `Invoke-Build ** ..`, but:
# - with two commands we test the omitted and specified parameter
# - we test core features first and demo scripts second
task AllTestScripts {
	# ** invokes all *.test.ps1
	Invoke-Build ** -Result Result1
	Invoke-Build ** ..\Tasks -Result Result2

	# Result can be used with **
	assert ($Result1.Tasks.Count -gt 0)
	assert ($Result2.Tasks.Count -gt 0)
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
	$log = [PowerShell]::Create().AddScript({
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
	}).Invoke() | Out-String

	$log
	assert $log.Contains('Build succeeded')
}

# Synopsis: Test a build invoked from a background job just to be sure it works.
task TestStartJob -If {$Host.Name -ne 'FarHost'} {
	$job = Start-Job { Invoke-Build . $args[0] } -ArgumentList "$BuildRoot\Dynamic.build.ps1"
	$log = Wait-Job $job | Receive-Job
	Remove-Job $job
	$log
	$info = Remove-Ansi $log[-1]
	assert ($info.StartsWith('Build succeeded. 5 tasks'))
}

# Synopsis: Show full help.
task ShowHelp -If (!$env:GITHUB_ACTION) {
	@(
		'Invoke-Build'
		'Build-Checkpoint'
		'Build-Parallel'
		'Add-BuildTask'
		'Assert-Build'
		'Assert-BuildEquals'
		'Get-BuildError'
		'Get-BuildProperty'
		'Get-BuildSynopsis'
		'Invoke-BuildExec'
		'Remove-BuildItem'
		'Resolve-MSBuild'
		'Set-BuildFooter'
		'Set-BuildHeader'
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
task Tests Dummy1, Dummy2, AllTestScripts, Conditional, Dynamic, TestDefaultParameter, TestExitCode, TestSelfAlias, TestStartJob

# Synopsis: This is the default task due its conventional name.
# Let's calls the samples and the main test task.
task . ParamsValues2, ParamsValues1, {
	"In default, action 1"
},
# It is possible to have several script jobs.
{
	"In default, action 2"
},
# Tasks can be referenced between or after actions.
Tests, InfoTasks, ShowHelp
