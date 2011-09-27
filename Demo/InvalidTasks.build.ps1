
<#
.Synopsis
	Tests of various invalid task definitions.

.Description
	If a build script has invalid tasks then it fails on the first. Thus, in
	order to test all the issues and avoid too many tiny script files this
	script creates these tiny build scripts with just one issue.
#>

# Writes a temp build script with issues, calls it, compares the message.
function Test($ExpectedMessagePattern, $Script) {
	# write the temp build script
	$Script > z.build.ps1

	# invoke it, catch the error, compare the message
	$message = ''
	try { Invoke-Build . z.build.ps1 }
	catch { $message = "$_" }
	$message
	if ($message -notlike $ExpectedMessagePattern) {
		Invoke-BuildError "Expected message pattern: [`n$ExpectedMessagePattern`n]"
	}

	# remove the temp script
	Remove-Item z.build.ps1
}

# Build scripts are not allowed to output script blocks. It makes no sense and,
# more likely, indicates a script job defined after a task, not as a parameter.
task ScriptOutput {
	Test "Build scripts should not output script blocks. *\z.build.ps1*" {
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
	Test "Task 'task1' is added twice:*1: *2: *" {
		task task1 {}
		# It is fine to reference a task 2+ times
		task task2 task1, task1, task1
		# This is wrong, task1 is already defined
		task task1 {}
	}
}

# Example of a missing task.
task TaskNotDefined {
	Test "Task 'task1': Job 1: Task 'missing' is not defined.*" {
		task task1 missing, {}
		task . task1, {}
	}
}

# Tasks with a cyclic reference: . -> task1 -> task2 -> task1 (oops!)
task CyclicReference {
	Test "Task 'task2': Job 1: Cyclic reference to 'task1'.*" {
		task task1 task2
		task task2 task1
		task . task1
	}
}

# The tested task has three valid jobs and one invalid (42 ~ [int]).
task InvalidJobType {
	Test "Task '.': Invalid job type." {
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

# The tested task uses valid job type but its value is invalid.
task InvalidJobValue {
	Test "Task '.': Hashtable task reference should have one item." {
		task . @(
			@{ task2 = 1; task1 = 1 }
		)
	}
}

# Incremental and Partial cannot be used together.
task IncrementalAndPartial {
	Test "Task '.': Parameters Incremental and Partial cannot be used together." {
		task . -Incremental @{} -Partial @{} { throw 'Unexpected.' }
	}
}

task . `
ScriptOutput,
TaskAddedTwice,
TaskNotDefined,
CyclicReference,
InvalidJobType,
InvalidJobValue,
IncrementalAndPartial
