
<#
.Synopsis
	Example of protected task jobs (@{Task=1} notation).

.Example
	Invoke-Build * Protected.build.ps1
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

# This task has two protected references to failing tasks.
task Survives1 @(
	# Tells to call the task Error1 and ignore its errors
	@{Error1=1}
	# Code invoked after the task Error1
	{
		"After Error1"

		$error1 = error Error1
		assert ($MyCountError1 -eq 1)
		assert ("$error1" -eq "Error1")

		$error2 = error Error2
		assert ($MyCountError2 -eq 0)
		assert ($null -eq $error2)
	}
	# Tells to call the task Error2 and ignore its errors
	@{Error2=1}
	# Code invoked after the task Error2
	{
		"After Error2"

		$error2 = error Error2
		assert ($MyCountError2 -eq 1)
		assert ("$error2" -eq "Error2")
	}
)

# Similar task. It checks that failed tasks are not called again.
task Survives2 @(
	# tells to call the task Error1 and ignore its failure
	@{Error1=1}
	# code invoked after the task Error1
	{
		"After Error1"

		$error1 = error Error1
		assert ($MyCountError1 -eq 1)
		assert ("$error1" -eq "Error1")
	}
	# tells to call the task Error2 and ignore its failure
	@{Error2=1}
	# code invoked after the task Error2
	{
		"After Error2"

		$error2 = error Error2
		assert ($MyCountError2 -eq 1)
		assert ("$error2" -eq "Error2")
	}
)

### Survives3, Survives4 use the same job list (there was an issue)

$JobList = @{Error1=1}, @{Error2=1}
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
	@{Error3=1},
	# Code invoked after the task Error3
	{
		"After Error3 -- this works"
	},
	# Tells to call the task Error4 and ignore its failure
	@{Error4=1},
	# This code is not going to be invoked
	{
		throw "After Error4 -- this is not called"
	}
)

# This task is prepared for errors in Error3, that is why build continues after
# the first error in AlmostSurvives1. But it is not prepared for errors in
# Error4, that is why the whole build fails. Note: it does not matter that the
# downstream task calls this as @{AlmostSurvives2=1}, AlmostSurvives2 is not
# ready for errors in Error4 (otherwise it would call it as @{Error4=1}).
task AlmostSurvives2 @(
	@{Error3=1},
	{},
	# This unprotected reference makes the build to fail.
	# IMPORTANT: This task AlmostSurvives2 is not even get called.
	'Error4'
	{}
)

# This task calls the tests and fails due to issues in the AlmostSurvives2.
# Even protected call does not help: AlmostSurvives2 is not protected from
# errors in Error4.
task AlmostSurvives AlmostSurvives1, @{AlmostSurvives2=1}

# Trigger tasks and check for expected results.
task . @{AlmostSurvives=1}, {
	Test-Error AlmostSurvives "Error4*At *\Protected.build.ps1*throw <<<<*"
}
