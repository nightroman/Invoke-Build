
<#
.Synopsis
	Tests invalid scripts and tasks.

.Description
	If a build script or a task is invalid then build fails on the first issue.
	In order to test all issues and avoid too many small invalid scripts this
	script creates and tests temporary scripts, one issue each.

.Example
	Invoke-Build * Invalid.test.ps1
#>

. .\Shared.ps1

# Writes a temporary script with an issue, calls it, compares the message.
function Test($ExpectedPattern, $Script, $Task = '.') {
	# write the temp script
	$Script > z.build.ps1

	# invoke
	try { Test-Issue $Task z.build.ps1 $ExpectedPattern }
	catch { Write-Error -ErrorAction Stop $_ }

	# remove the temp script
	Remove-Item z.build.ps1
}

# Build scripts should have at least one task.
task NoTasks {
	Test "No tasks in '*\z.build.ps1'.*OperationStopped*" {
		# Script with no tasks
	}
}

# The task has three valid jobs and one invalid (42 ~ invalid type).
task InvalidJobType {
	Test "Task 'InvalidJob': Invalid job.*At *InvalidArgument*" {
		task task1 {}
		task task2 {}
		task InvalidJob @(
			'task1'           # [string] - task name
			(job task2 -Safe) # [object] - tells to ignore task2 errors
			{ $x = 123 }      # [scriptblock] - code invoked as this task
			42                # all other types are invalid
		)
	}
}

# The task has invalid job value.
task InvalidJobValue {
	Test "Task 'InvalidJobValue': Invalid job.*InvalidJobValue @(*InvalidArgument*" {
		task InvalidJobValue @(
			@{ task2 = 1; task1 = 1 }
		)
	}
}

# The task has invalid value in After.
task InvalidJobValueAfter {
	Test "Task 'InvalidAfter': Invalid job.*InvalidAfter -After*OperationStopped*" {
		task InvalidAfter -After @{}
	}
}

# The task has invalid value in Before.
task InvalidJobValueBefore {
	Test "Task 'InvalidBefore': Invalid job.*InvalidBefore -Before*OperationStopped*" {
		task InvalidBefore -Before @{}
	}
}

# Missing task in jobs.
task TaskNotDefined {
	Test "Task 'task1': Missing task 'missing'.*At *\z.build.ps1:*OperationStopped*" {
		task TaskNotDefined task1, {}
		task task1 missing, {}
	}
}

# Missing task in After.
task TaskNotDefinedAfter {
	Test "Task 'AfterMissing': Missing task 'MissingTask'.*At *\z.build.ps1*OperationStopped*" {
		task AfterMissing -After MissingTask {}
	}
}

# Missing task in Before.
task TaskNotDefinedBefore {
	Test "Task 'BeforeMissing': Missing task 'MissingTask'.*At *\z.build.ps1*OperationStopped*" {
		task BeforeMissing -Before MissingTask {}
	}
}

# Tasks with a cyclic reference: . -> task1 -> task2 -> task1
task CyclicReference {
	Test "Task 'task2': Cyclic reference to 'task1'.*At *\z.build.ps1:*OperationStopped*" {
		task CyclicReference task1
		task task1 task2
		task task2 task1
	}
}

# Cyclic references should be caught on ? as well.
task CyclicReferenceList {
	Test -Task ? "Task 'test2': Cyclic reference to 'test1'.*At *\z.build.ps1:*OperationStopped*" {
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
