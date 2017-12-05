
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
	assert ($r[-3] -clike 'WARNING: demo-file-warning File: *Errors.test.ps1.')
	assert ($r[-2] -clike 'WARNING: demo-task-warning Task: t1. File: *Errors.test.ps1.')
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
