
<#
.Synopsis
	Example of a task with a task job of invalid type.

.Description
	Valid task job types are:
	* [string] - existing task name
	* [hashtable] - @{ Name = Option}
	* [scriptblock] - code invoked as this task

.Example
	# This fails due to the invalid job type:
	Invoke-Build . TaskInvalidJob.build.ps1

.Example
	# Although the script still have issues this command works
	# because only tasks to be invoked are checked:
	Invoke-Build task1 TaskInvalidJob.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

task task1 {}
task task2 {}

# this task uses three valid job types and one invalid
task . @(
	'task1'        # [string] - task name
	@{ task2 = 1 } # [hashtable] - tells ignore errors in task2
	{ $x = 123 }   # [scriptblock] - code invoked as this task
	42             # all other types are invalid
)
