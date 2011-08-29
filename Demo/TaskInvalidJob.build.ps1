
<#
.Synopsis
	Tasks with invalid job types or values.

.Description
	Valid task job types are:
	* [string] - existing task name
	* [hashtable] - @{ Name = Option }
	* [scriptblock] - code invoked as this task

	NOTE: The script has the parameter Test in order to add one problem task at
	a time. Otherwise the test would always fail at the first problem task and
	the others could not be tested.

.Example
	># These commands fail due to the invalid jobs:
	Invoke-Build InvalidJobType TaskInvalidJob.build.ps1
	Invoke-Build InvalidJobValue TaskInvalidJob.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

param($Test)

task task1 {}
task task2 {}

# This task has three valid jobs and one invalid
if ($Test -eq 'InvalidJobType') {
	task InvalidJobType @(
		'task1'        # [string] - task name
		@{ task2 = 1 } # [hashtable] - tells ignore errors in task2
		{ $x = 123 }   # [scriptblock] - code invoked as this task
		42             # all other types are invalid
	)
}

# This task uses valid job type but invalid job value
if ($Test -eq 'InvalidJobValue') {
	task InvalidJobValue @(
		@{ task2 = 1; task1 = 1 }
	)
}
