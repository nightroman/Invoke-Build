
<#
.Synopsis
	Example of imported tasks and data (like MSBuild .targets file).

.Description
	See .build.ps1, the line with SharedTasksData.tasks.ps1 and comments.
	It is also imported by TryTasks.build.ps1 and TryTasksFails.build.ps1.
#>

$MySharedValue1 = 'shared 1'
task SharedValueTask1 {
	'SharedValueTask1'

	# test: the value is available
	assert (Test-Path Variable:\MySharedValue1)

	# use the value (just output in here)
	"MySharedValue1='$MySharedValue1'"
}

# This task fails (but increments its call counter).
$MyCountError1 = 0
task Error1 {
	++$script:MyCountError1
	"In Error1"
	throw "Error1"
}

# This task is the same as Error1, it just uses different names.
$MyCountError2 = 0
task Error2 {
	++$script:MyCountError2
	"In Error2"
	throw "Error2"
}
