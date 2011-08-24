
<#
.Synopsis
	Examples of job tasks using @{Name=Option} notation.

.Link
	Invoke-Build
	.build.ps1
#>

# this task fails
task Error1 {
	"In Error1"
	throw "Error1"
}

# and this task fails
task Error2 {
	"In Error2"
	throw "Error2"
}

# this task has two references to failing tasks
task . @(
	# tells to call the task Error1 and ignore its failure
	@{Error1 = 1},
	# code invoked after the task Error1
	{
		"After Error1"

		$error1 = Get-Error Error1
		assert ("$error1" -eq "Error1")

		$error2 = Get-Error Error2
		assert ($null -eq $error2)
	},
	# tells to call the task Error2 and ignore its failure
	@{Error2 = 1},
	# code invoked after the task Error2
	{
		"After Error2"

		$error2 = Get-Error Error2
		assert ("$error2" -eq "Error2")
	}
)
