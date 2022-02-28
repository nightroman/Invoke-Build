<#
.Synopsis
	Tests safe jobs.
#>

Import-Module .\Tools

# This task fails (but increments its call counter).
$MyCountError1 = 0
task Error1 {
	++$script:MyCountError1
	"In Error1"
	throw "Error1"
}

# This task is the same as Error1 but uses different names.
$MyCountError2 = 0
task Error2 {
	++$script:MyCountError2
	"In Error2"
	throw "Error2"
}

# This task has two safe references to failing tasks.
task Survives1 @(
	# Tells to call the task Error1 and ignore its errors
	'?Error1'
	# Code invoked after the task Error1
	{
		"After Error1"

		$error1 = Get-BuildError Error1
		equals $MyCountError1 1
		equals "$error1" Error1

		$error2 = Get-BuildError Error2
		equals $MyCountError2 0
		equals $error2
	}
	# Tells to call the task Error2 and ignore its errors
	'?Error2'
	# Code invoked after the task Error2
	{
		"After Error2"

		$error2 = Get-BuildError Error2
		equals $MyCountError2 1
		equals "$error2" Error2
	}
)

# Similar task. It checks that failed tasks are not called again.
task Survives2 @(
	#! run test 1 which fails two safe tasks
	'Survives1'
	# tells to call the task Error1 and ignore its failure
	'?Error1'
	# code invoked after the task Error1
	{
		"After Error1"

		$error1 = Get-BuildError Error1
		equals $MyCountError1 1 #! not 2
		equals "$error1" Error1
	}
	# tells to call the task Error2 and ignore its failure
	'?Error2'
	# code invoked after the task Error2
	{
		"After Error2"

		$error2 = Get-BuildError Error2
		equals $MyCountError2 1 #! not 2
		equals "$error2" Error2
	}
)

### Survives3, Survives4 use the same job list (there was an issue)

$JobList = '?Error1', '?Error2'
task Survives3 $JobList
task Survives4 $JobList

### AlmostSurvives

# For AlmostSurvives
task Error3 {throw 'Error3'}
task Error4 {throw 'Error4'}

# This task is prepared to survive on errors in Error3 and Error4. It survives
# if it is called alone. But if it is called together with AlmostSurvives2 then
# it fails because the error in Error4 is going to break AlmostSurvives2.
task AlmostSurvives1 @(
	# Tells to call the task Error3 and ignore its failure
	'?Error3'
	# Code invoked after the task Error3
	{
		"After Error3 -- this works"
	}
	# Tells to call the task Error4 and ignore its failure
	'?Error4'
	# This code is not going to be invoked
	{
		throw "After Error4 -- this is not called"
	}
)

# This task is ready for errors in Error3, that is why build continues after
# the first error in AlmostSurvives1. But it is not ready for errors in Error4,
# that is why the whole build fails even though AlmostSurvives calls this task
# safe.
task AlmostSurvives2 @(
	'?Error3'
	{}
	# This unprotected reference makes the build to fail.
	# IMPORTANT: This task AlmostSurvives2 is not even get called.
	'Error4'
	{}
)

# This task calls the tests and fails due to issues in the AlmostSurvives2.
# Even safe call does not help: AlmostSurvives2 is not ready for errors in
# Error4.
task AlmostSurvives AlmostSurvives1, ?AlmostSurvives2

# Trigger tasks and check for expected results.
task TestAlmostSurvives ?AlmostSurvives, {
	Test-Error (Get-BuildError AlmostSurvives) "Error4*At *Safe.test.ps1*'Error4'*OperationStopped*"
}

### DependsOnFailedDirectlyAndIndirectly
# This test covers issues fixed in 1.5.2

task FailedUsedByMany {
	throw 'Oops in FailedUsedByMany'
}
task DependsOnFailed FailedUsedByMany, {
	throw 'Must not be called'
}
task DependsOnFailedDirectlyAndIndirectly ?FailedUsedByMany, ?DependsOnFailed, {
	throw 'Must not be called'
}
task TestDependsOnFailedDirectlyAndIndirectly ?DependsOnFailedDirectlyAndIndirectly, {
	# error of initial failure
	equals "$(Get-BuildError FailedUsedByMany)" 'Oops in FailedUsedByMany'

	# no error because it is not called, even if it is called safe itself it
	# also calls the failed task unsafe
	equals (Get-BuildError DependsOnFailed)

	# error, even if it calls the failed task safe it also calls another task
	# which leads to unsafe calls of the failed task
	equals "$(Get-BuildError DependsOnFailedDirectlyAndIndirectly)" 'Oops in FailedUsedByMany'
}

### Misc

# Test missing task
task ErrorMissingTask {
	($r = try {<##> Get-BuildError missing} catch {$_})
	equals "$r" "Missing task 'missing'."
	assert $r.InvocationInfo.PositionMessage.Contains('<##>')
}

# Safe tasks in the command line
task SafeParameter {
	$file = {
		task t1 {throw 42}
		task t2 {}
	}
	Invoke-Build ?t1, t2 $file -Result r

	equals $r.Error
	equals $r.Tasks.Count 2
	equals $r.Errors.Count 1
}
