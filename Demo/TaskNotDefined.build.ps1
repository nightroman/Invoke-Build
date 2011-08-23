
<#
.Synopsis
	Example of a missing task call and failure.

.Example
	# This fails because the 'missing' task is missing:
	Invoke-Build default TaskNotFound.build.ps1

.Link
	.build.ps1
#>

task task1 missing, {}

task default task1, {}
