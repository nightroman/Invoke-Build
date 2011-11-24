
<#
.Synopsis
	Tests invalid scripts and tasks.

.Description
	If a build script or a task is invalid then build fails on the first issue.
	In order to test all issues and avoid too many small invalid scripts this
	script creates and tests temporary scripts, one issue each.

.Example
	Invoke-Build * InvalidTasks.build.ps1
#>

. .\SharedScript.ps1

# Writes a temporary script with an issue, calls it, compares the message.
function Test($ExpectedPattern, $Script, $Task = '.') {
	# write the temp script
	$Script > z.build.ps1

	# invoke, catch, compare
	$message = ''
	try { Invoke-Build $Task z.build.ps1 }
	catch { $message = Format-Error $_ }
	Write-BuildText Magenta $message
	if ($message -notlike $ExpectedPattern) {
		Write-Error -ErrorAction Stop @"
Expected pattern [
$ExpectedPattern
]
Actual error [
$message
]
"@
	}

	# remove the temp script
	Remove-Item z.build.ps1
}

# Build scripts should have at least one task.
task NoTasks {
	Test "There is no task in '*\z.build.ps1'.*OperationStopped*" {
		# Script with no tasks
	}
}

# Build scripts should not output script blocks. This often indicates a typical
# mistake when a script is defined starting from a new line (tasks are function
# calls, not definitions).
task ScriptOutput {
	Test "Invalid build script syntax at the script block {*}*At *OperationStopped*" {
		task task1
		'It is fine to output some data ...'
		task task2 task1
		{
			'... but this script block is a mistake.'
		}
	}
}

# Task names should be unique. But it is fine to use the same task name several
# times in a task job list (this does not make much sense though).
task TaskAddedTwice {
	Test "Task 'task1': Task name already exists:*At*\z.build.ps1:2 *At*\z.build.ps1:6 *InvalidArgument*" {
		task task1 {}
		# It is fine to reference a task 2+ times
		task task2 task1, task1, task1
		# This is wrong, task1 is already defined
		task task1 {}
	}
}

# The task has three valid jobs and one invalid (42 ~ [int]).
task InvalidJobType {
	Test "Task '.': Invalid job type.*At *InvalidArgument*" {
		task task1 {}
		task task2 {}
		task . @(
			'task1'        # [string] - task name
			@{ task2 = 1 } # [hashtable] - tells to ignore task2 errors
			{ $x = 123 }   # [scriptblock] - code invoked as this task
			42             # all other types are invalid
		)
	}
}

# The task has invalid job value.
task InvalidJobValue {
	Test "Task '.': Invalid pair, expected hashtable @{X = Y}.*task <<<<*InvalidArgument*" {
		task . @(
			@{ task2 = 1; task1 = 1 }
		)
	}
}

# The task has invalid value in After.
task InvalidJobValueAfter {
	Test "Task 'InvalidAfter': Invalid pair, expected hashtable @{X = Y}.*task <<<<  InvalidAfter*OperationStopped*" {
		task InvalidAfter -After @{}
	}
}

# The task has invalid value in Before.
task InvalidJobValueBefore {
	Test "Task 'InvalidBefore': Invalid pair, expected hashtable @{X = Y}.*task <<<<  InvalidBefore*OperationStopped*" {
		task InvalidBefore -Before @{}
	}
}

# Incremental and Partial cannot be used together.
task IncrementalAndPartial {
	Test "Parameter set cannot be resolved using the specified named parameters.*At*task <<<<*InvalidArgument*" {
		task . -Incremental @{} -Partial @{} { throw 'Unexpected.' }
	}
}

# Invalid Incremental/Partial hashtable.
task IncrementalInvalidHashtable {
	Test "Task '.': Invalid pair, expected hashtable @{X = Y}.*task <<<<*InvalidArgument*" {
		task . -Incremental @{} { throw 'Unexpected.' }
	}
	Test "Task '.': Invalid pair, expected hashtable @{X = Y}.*task <<<<*InvalidArgument*" {
		task . -Partial @{} { throw 'Unexpected.' }
	}
}

# Missing task in jobs.
task TaskNotDefined {
	Test "Task 'task1': Task 'missing' is not defined.*At *\z.build.ps1:2 *OperationStopped*" {
		task task1 missing, {}
		task . task1, {}
	}
}

# Missing task in After.
task TaskNotDefinedAfter {
	Test "Task 'AfterMissing': Task 'MissingTask' is not defined.*At *\InvalidTasks.build.ps1*OperationStopped*" {
		task AfterMissing -After MissingTask {}
	}
}

# Missing task in Before.
task TaskNotDefinedBefore {
	Test "Task 'BeforeMissing': Task 'MissingTask' is not defined.*At *\InvalidTasks.build.ps1*OperationStopped*" {
		task BeforeMissing -Before MissingTask {}
	}
}

# Tasks with a cyclic reference: . -> task1 -> task2 -> task1
task CyclicReference {
	Test "Task 'task2': Cyclic reference to 'task1'.*At *\z.build.ps1:3 *OperationStopped*" {
		task task1 task2
		task task2 task1
		task . task1
	}
}

# Cyclic references should be caught on ? as well.
task CyclicReferenceList {
	Test -Task ? "Task 'test2': Cyclic reference to 'test1'.*At *\z.build.ps1:3 *OperationStopped*" {
		task test1 test2
		task test2 test1
	}
}
# Cyclic references should be caught on * as well.
task CyclicReferenceStar {
	Test -Task * "Task 'test2': Cyclic reference to 'test1'.*At *\z.build.ps1:3 *OperationStopped*" {
		task test1 test2
		task test2 test1
	}
}
