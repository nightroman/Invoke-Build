
<#
.Synopsis
	Test safe jobs.
#>

. .\Shared.ps1

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
	(job Error1 -Safe)
	# Code invoked after the task Error1
	{
		"After Error1"

		$error1 = error Error1
		equals $MyCountError1 1
		equals "$error1" Error1

		$error2 = error Error2
		equals $MyCountError2 0
		equals $error2
	}
	# Tells to call the task Error2 and ignore its errors
	(job Error2 -Safe)
	# Code invoked after the task Error2
	{
		"After Error2"

		$error2 = error Error2
		equals $MyCountError2 1
		equals "$error2" Error2
	}
)

# Similar task. It checks that failed tasks are not called again.
task Survives2 @(
	# tells to call the task Error1 and ignore its failure
	(job Error1 -Safe)
	# code invoked after the task Error1
	{
		"After Error1"

		$error1 = error Error1
		equals $MyCountError1 1
		equals "$error1" Error1
	}
	# tells to call the task Error2 and ignore its failure
	(job Error2 -Safe)
	# code invoked after the task Error2
	{
		"After Error2"

		$error2 = error Error2
		equals $MyCountError2 1
		equals "$error2" Error2
	}
)

### Survives3, Survives4 use the same job list (there was an issue)

$JobList = (job Error1 -Safe), (job Error2 -Safe)
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
	(job Error3 -Safe)
	# Code invoked after the task Error3
	{
		"After Error3 -- this works"
	}
	# Tells to call the task Error4 and ignore its failure
	(job Error4 -Safe)
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
	(job Error3 -Safe)
	{}
	# This unprotected reference makes the build to fail.
	# IMPORTANT: This task AlmostSurvives2 is not even get called.
	'Error4'
	{}
)

# This task calls the tests and fails due to issues in the AlmostSurvives2.
# Even safe call does not help: AlmostSurvives2 is not ready for errors in
# Error4.
task AlmostSurvives AlmostSurvives1, (job AlmostSurvives2 -Safe)

# Trigger tasks and check for expected results.
task TestAlmostSurvives (job AlmostSurvives -Safe), {
	Test-Error AlmostSurvives "Error4*At *\Safe.test.ps1*'Error4'*OperationStopped*"
}

### DependsOnFailedDirectlyAndIndirectly
# This test covers issues fixed in 1.5.2

task FailedUsedByMany {
	throw 'Oops in FailedUsedByMany'
}
task DependsOnFailed FailedUsedByMany, {
	throw 'Must not be called'
}
task DependsOnFailedDirectlyAndIndirectly (job FailedUsedByMany -Safe), (job DependsOnFailed -Safe), {
	throw 'Must not be called'
}
task TestDependsOnFailedDirectlyAndIndirectly (job DependsOnFailedDirectlyAndIndirectly -Safe), {
	# error of initial failure
	equals "$(error FailedUsedByMany)" 'Oops in FailedUsedByMany'

	# no error because it is not called, even if it is called safe itself it
	# also calls the failed task unsafe
	equals (error DependsOnFailed)

	# error, even if it calls the failed task safe it also calls another task
	# which leads to unsafe calls of the failed task
	equals "$(error DependsOnFailedDirectlyAndIndirectly)" 'Oops in FailedUsedByMany'
}

### Misc

# Test missing task
task ErrorMissingTask {
	($r = try {<##> error missing} catch {$_})
	equals "$r" "Missing task 'missing'."
	assert $r.InvocationInfo.PositionMessage.Contains('<##>')
}
