
<#
.Synopsis
	Example of job tasks using @{Task=1} notation.

.Link
	Invoke-Build
	.build.ps1
#>

$CountError1 = 0
$CountError2 = 0

# this task fails (but increments its call counter)
task Error1 {
	++$script:CountError1
	"In Error1"
	throw "Error1"
}

# and this task fails (but updates its counter, too)
task Error2 {
	++$script:CountError2
	"In Error2"
	throw "Error2"
}

# this task has two references to failing tasks with options to ignore errors
task Survives1 @(
	# tells to call the task Error1 and ignore its failure
	@{Error1 = 1}
	# code invoked after the task Error1
	{
		"After Error1"

		$error1 = Get-Error Error1
		assert ($CountError1 -eq 1)
		assert ("$error1" -eq "Error1")

		$error2 = Get-Error Error2
		assert ($CountError2 -eq 0)
		assert ($null -eq $error2)
	}
	# tells to call the task Error2 and ignore its failure
	@{Error2 = 1}
	# code invoked after the task Error2
	{
		"After Error2"

		$error2 = Get-Error Error2
		assert ($CountError2 -eq 1)
		assert ("$error2" -eq "Error2")
	}
)

# this task is almost the same, it checks that failed tasks are not called
task Survives2 @(
	# tells to call the task Error1 and ignore its failure
	@{Error1 = 1}
	# code invoked after the task Error1
	{
		"After Error1"

		$error1 = Get-Error Error1
		assert ($CountError1 -eq 1)
		assert ("$error1" -eq "Error1")
	}
	# tells to call the task Error2 and ignore its failure
	@{Error2 = 1}
	# code invoked after the task Error2
	{
		"After Error2"

		$error2 = Get-Error Error2
		assert ($CountError2 -eq 1)
		assert ("$error2" -eq "Error2")
	}
)

# the default task calls the tests
task . Survives1, Survives2
