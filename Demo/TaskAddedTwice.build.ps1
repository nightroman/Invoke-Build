
<#
.Synopsis
	Example of a build script with duplicated tasks.

.Example
	# This fails due to duplicated tasks:
	Invoke-Build default TaskAddedTwice.build.ps1

.Link
	.build.ps1
#>

task task1 {}
task task1 {}
