
<#
.Synopsis
	Example of protected task jobs (@{Task=1} notation).

.Example
	Invoke-Build . ProtectedTasks.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

# Import tasks Error1 and Error2 (dot-sourced because imported with data).
. .\SharedTasksData.tasks.ps1

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

# Survives3, Survives4 cover a case with a shared job list (there was an issue)
$JobList = @{Error1=1}, @{Error2=1}
task Survives3 $JobList
task Survives4 $JobList

# The default task calls the tests.
task . Survives1, Survives2, Survives3, Survives4
