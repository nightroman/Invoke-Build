
<#
.Synopsis
	Example of a task with a job of invalid type.

.Description
	Valid task job types are:
	* [string] - names of an existing job
	* [scriptblock] - code executed as this task

.Example
	# This fails due to the invalid job type:
	Invoke-Build default TaskInvalidJob.build.ps1

.Example
	# This works; only tasks to be invoked are validated:
	Invoke-Build task1 TaskInvalidJob.build.ps1

.Link
	.build.ps1
#>

task task1 {}

task default task1, {}, 42
