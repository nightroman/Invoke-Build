
<#
.Synopsis
	Uses parametrized tasks.

.Description
	Invoke all tasks to see how it works

		Invoke-Build * -Summary

	Take a look at the summary information. See that imported custom tasks are
	treated as defined where they are imported (different places), not created
	(same place).

	Similarly, the command

		Invoke-Build ?

	shows synopsis comments from where a custom task is imported.
#>

### Simple approach with a function

function Invoke-Something($Param1, $Param2) {
	"
	Param1 = $Param1
	Param2 = $Param2
	"
}

# Synopsis: Invoke-Something with some parameters.
task Something1 {
	Invoke-Something data1 data2
}

# Synopsis: Invoke-Something with other parameters.
task Something2 {
	Invoke-Something data3 data4
}

### Advanced approach with a custom task

# Synopsis: Custom task with some parameters.
.\Param.task.ps1 CustomTask1 data1 data2

# Synopsis: Custom task with other parameters.
.\Param.task.ps1 CustomTask2 data3 data4
