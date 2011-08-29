
<#
.Synopsis
	Example of a build script with conflicting task names.

.Description
	Tasks with same names cannot be added twice. Note: but it is fine to use
	the same task two or more times in a task job list (it does not make much
	sense though).

.Example
	># This fails:
	Invoke-Build . TaskAddedTwice.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

task task1 {}

# It is fine to reference a task 2+ times
task task2 task1, task1, task1

# This is wrong, task1 is already defined
task task1 {}
