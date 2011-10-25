
<#
.Synopsis
	Tests invalid scripts and tasks.

.Description
	If a build script or a task is invalid then build fails on the first issue.
	In order to test all issues and avoid too many small invalid scripts this
	script creates and tests temporary scripts, one issue each.
#>

# Writes a temporary script with an issue, calls it, compares the message.
function Test($ExpectedMessagePattern, $Script) {
	# write the temp script
	$Script > z.build.ps1

	# invoke it, catch the error, compare the message
	$message = ''
	try { Invoke-Build . z.build.ps1 }
	catch { $message = $_ | Out-String }
	Write-BuildText Magenta $message
	if ($message -notlike $ExpectedMessagePattern) {
		Invoke-BuildError "Expected message pattern: [`n$ExpectedMessagePattern`n]"
	}

	# remove the temp script
	Remove-Item z.build.ps1
}

# Build scripts should have at least one task defined.
task NoTasks {
	Test "*\Invoke-Build.ps1 : There is no task in the script.*InvalidOperation*z.build.ps1:String*" {
		# Script with no tasks
	}
}

# Build scripts are not allowed to output script blocks. It makes no sense and,
# more likely, indicates a script job defined after a task, not as a parameter.
task ScriptOutput {
	Test "*\Invoke-Build.ps1 : Invalid build script syntax at the script block {*}*At *InvalidOperation*" {
		task task1
		'It is fine to output some data ...'
		task task2 task1
		{
			'... but this script block is a mistake.'
		}
	}
}

# Tasks with same names cannot be added twice. But it is fine to use the same
# task 2+ times in a task job list (it does not make much sense though).
task TaskAddedTwice {
	Test "Add-BuildTask : Task 'task1': Task name already exists:*At*\z.build.ps1:2 *At*\z.build.ps1:6 *InvalidArgument*" {
		task task1 {}
		# It is fine to reference a task 2+ times
		task task2 task1, task1, task1
		# This is wrong, task1 is already defined
		task task1 {}
	}
}

# The task has three valid jobs and one invalid (42 ~ [int]).
task InvalidJobType {
	Test "Add-BuildTask : Task '.': Invalid job type.*At *InvalidArgument*" {
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
	Test "Add-BuildTask : Task '.': Invalid pair, expected hashtable @{X = Y}.*task <<<<*InvalidArgument*" {
		task . @(
			@{ task2 = 1; task1 = 1 }
		)
	}
}

# The task has invalid value in After.
task InvalidJobValueAfter {
	Test "*\Invoke-Build.ps1 : Task 'InvalidAfter': Invalid pair, expected hashtable @{X = Y}.*task <<<<  InvalidAfter*InvalidArgument*" {
		task InvalidAfter -After @{}
	}
}

# The task has invalid value in Before.
task InvalidJobValueBefore {
	Test "*\Invoke-Build.ps1 : Task 'InvalidBefore': Invalid pair, expected hashtable @{X = Y}.*task <<<<  InvalidBefore*InvalidArgument*" {
		task InvalidBefore -Before @{}
	}
}

# Incremental and Partial cannot be used together.
task IncrementalAndPartial {
	Test "Add-BuildTask : Parameter set cannot be resolved using the specified named parameters.*At*task <<<<*AmbiguousParameterSet*" {
		task . -Incremental @{} -Partial @{} { throw 'Unexpected.' }
	}
}

# Invalid Incremental/Partial hashtable.
task IncrementalInvalidHashtable {
	Test "Add-BuildTask : Task '.': Invalid pair, expected hashtable @{X = Y}.*task <<<<*InvalidArgument*" {
		task . -Incremental @{} { throw 'Unexpected.' }
	}
	Test "Add-BuildTask : Task '.': Invalid pair, expected hashtable @{X = Y}.*task <<<<*InvalidArgument*" {
		task . -Partial @{} { throw 'Unexpected.' }
	}
}

# Missing task in jobs.
task TaskNotDefined {
	Test "*\Invoke-Build.ps1 : Task 'task1': Task 'missing' is not defined.*At *\z.build.ps1:2 *ObjectNotFound: (:)*" {
		task task1 missing, {}
		task . task1, {}
	}
}

# Missing task in After.
task TaskNotDefinedAfter {
	Test "*\Invoke-Build.ps1 : Task 'AfterMissing': Task 'MissingTask' is not defined.*At *\InvalidTasks.build.ps1*InvalidArgument: (:)*" {
		task AfterMissing -After MissingTask {}
	}
}

# Missing task in Before.
task TaskNotDefinedBefore {
	Test "*\Invoke-Build.ps1 : Task 'BeforeMissing': Task 'MissingTask' is not defined.*At *\InvalidTasks.build.ps1*InvalidArgument: (:)*" {
		task BeforeMissing -Before MissingTask {}
	}
}

# Tasks with a cyclic reference: . -> task1 -> task2 -> task1 (oops!). (Task preprocessing).
task CyclicReference {
	Test "*\Invoke-Build.ps1 : Task 'task2': Cyclic reference to 'task1'.*At *\z.build.ps1:3 *InvalidOperation: (:)*" {
		task task1 task2
		task task2 task1
		task . task1
	}
}

task . `
NoTasks,
ScriptOutput,
TaskAddedTwice,
InvalidJobType,
InvalidJobValue,
InvalidJobValueAfter,
InvalidJobValueBefore,
IncrementalAndPartial,
IncrementalInvalidHashtable,
TaskNotDefined,
TaskNotDefinedAfter,
TaskNotDefinedBefore,
CyclicReference
