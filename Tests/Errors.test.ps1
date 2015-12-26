
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
	{
		; task Test {42}
		function Exit-Build {throw 13}
	} > z.build.ps1

	Invoke-Build . z.build.ps1 -Safe -Result Result

	equals $Result.Errors.Count 1
	equals $Result.Errors[0].Task

	Remove-Item z.build.ps1
}

<#
Any custom error, i.e. set by a task itself as Task.Error, is added to the
result errors. This may look inconsistent with normal errors: only the child
error is added to result errors and for parents it is only set as Task.Error.

There is a difference. In case of custom errors it is a parent task decides to
error or not and what error to set, it may even change an error, not propagate
like in this test. Thus, the engine adds all custom errors. If it does the same
for normal errors then it would just duplicate the same error for all parents.

This test also covers an originally made mistake. The current task should be
added to errors ($Task), not the last (${*}.Task). In the latter this test used
to add 3 identical errors for the task Test1.
#>
task 'Custom child errors added for parent tasks' {
	{
		. ..\Tasks\Test\Test.tasks.ps1
		; test Test1 {throw 'Oops Test1'}
		; test Test2 Test1, {assert 0}
		; test Test3 Test2, {assert 0}
	} > z.build.ps1

	Invoke-Build Test3 z.build.ps1 -Result Result

	equals $Result.Errors.Count 3
	equals $Result.Errors[0].Task.Name 'Test1'
	equals $Result.Errors[1].Task.Name 'Test2'
	equals $Result.Errors[2].Task.Name 'Test3'

	Remove-Item z.build.ps1
}

task Warnings {
	{
		Write-Warning demo-file-warning
		; task t1 {Write-Warning demo-task-warning}
	} > z.build.ps1

	($r = Invoke-Build t1 z.build.ps1 -Result Result)

	# output
	assert ($r[-3] -clike 'WARNING: demo-file-warning File: *\z.build.ps1.')
	assert ($r[-2] -clike 'WARNING: demo-task-warning Task: t1. File: *\z.build.ps1.')
	assert ($r[-1] -clike 'Build succeeded with warnings. 1 tasks, 0 errors, 2 warnings *')

	# result
	equals $Result.Warnings.Count 2
	$1, $2 = $Result.Warnings
	equals $1.Message 'demo-file-warning'
	assert ($1.File -like '*\z.build.ps1')
	equals $1.Task
	equals $2.Message 'demo-task-warning'
	assert ($2.File -like '*\z.build.ps1')
	equals $2.Task.Name 't1'

	Remove-Item z.build.ps1
}
