
<#
.Synopsis
	Tests build result `Errors`.

.Description
	When a build is invoked like

		Invoke-Build ... -Result Result

	then the variable $Result contains info about the build. Its property
	Errors is the list of build errors. This script tests these objects.

.Example
	Invoke-Build * Errors.test.ps1
#>

# The last task ${*}.Task should be reset before Exit-Build.
task 'Exit-Build error should have no task' {
	Invoke-Build . -Safe -Result Result {
		task Test {42}
		Exit-Build {throw 13}
	}

	equals $Result.Errors.Count 1
	equals $Result.Errors[0].Task
}

task Warnings {
	$file = {
		Write-Warning demo-file-warning
		task t1 {Write-Warning demo-task-warning}
	}
	($r = Invoke-Build t1 $file -Result Result)

	# output
	assert ($r[-5] -cmatch '^WARNING: .*Errors\.test\.ps1:\d+$')
	equals $r[-4] demo-file-warning
	assert ($r[-3] -cmatch '^WARNING: /t1 .*Errors\.test\.ps1:\d+$')
	equals $r[-2] demo-task-warning
	assert ($r[-1] -clike 'Build succeeded with warnings. 1 tasks, 0 errors, 2 warnings *')

	# result
	equals $Result.Warnings.Count 2
	$1, $2 = $Result.Warnings
	equals $1.Message demo-file-warning
	equals $1.File $BuildFile
	equals $1.Task
	equals $2.Message demo-task-warning
	equals $2.File $BuildFile
	equals $2.Task.Name t1
}

task ExitCodeOnSafe {
	# 0 on build errors in sessions (hence should be 0 in exec).
	# Formal test, sessions should not use $LASTEXITCODE.
	$global:LASTEXITCODE = 42
	Invoke-Build -Safe missing {task t1}
	equals $global:LASTEXITCODE 0

	# 0 on build errors in exec (redundant test, in theory).
	# This test covers real scenarios.
	$global:LASTEXITCODE = 42
	Invoke-PowerShell -Command Invoke-Build missing $BuildFile -Safe
	equals $global:LASTEXITCODE 0

	# 1 on argument errors in exec.
	# This test covers real scenarios.
	$global:LASTEXITCODE = 42
	Invoke-PowerShell -Command Invoke-Build missing missing -Safe
	equals $global:LASTEXITCODE 1

	# On argument errors in sessions $LASTEXITCODE is undefined (old).
	# This case is not tested, sessions should not use $LASTEXITCODE.
}
