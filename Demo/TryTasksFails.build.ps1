
<#
.Synopsis
	Example of job tasks using @{Task=1} notation.

.Description
	This test is similar to TryTasks.build.ps1 but shows a subtle failure.

.Link
	Invoke-Build
	.build.ps1
#>

# fails
task Error1 {
	"In Error1"
	throw "Error1"
}

# fails
task Error2 {
	"In Error2"
	throw "Error2"
}

# This task is prepared to survive on errors in Error1 and Error2. It would
# survive but the error in Error2 will cause the task Fails to fail.
task AlmostSurvives @(
	# tells to call the task Error1 and ignore its failure
	@{Error1 = 1},
	# code invoked after the task Error1
	{
		"After Error1 -- this works"
	},
	# tells to call the task Error2 and ignore its failure
	@{Error2 = 1},
	# this code is not going to be invoked
	{
		"After Error2 -- this is not called"
	}
)

# This task is prepared for errors in Error1, that is why build continues after
# the first error in the task AlmostSurvives. But this task is not prepared for
# errors in Error2, that is why the whole build fails. Note: it does not matter
# that the downstream task calls this as @{Fails=1}, the task Fails is not
# ready for errors in Error2 (otherwise it would call it as @{Error2=1}).
task Fails @(
	@{Error1 = 1},
	{},
	# this is going to fail
	'Error2'
	{}
)

# This task calls the tests and fails due to issues in the Fails. Even prepared
# for errors call @{Fails=1} does not help because Fails is not prepared for
# errors in Error2.
task . AlmostSurvives, @{Fails=1}
