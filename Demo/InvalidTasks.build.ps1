
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
	catch { $message = $_ | Out-String }
	Write-BuildText Magenta $message
	if ($message -notlike $ExpectedMessagePattern) {
		Invoke-BuildError "Expected message pattern: [`n$ExpectedMessagePattern`n]"
	}

	# remove the temp script
	Remove-Item z.build.ps1
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
	Test "Add-BuildTask : Task 'task1' is added twice.*At*\z.build.ps1:2 *At*\z.build.ps1:6 *InvalidOperation*" {
		task task1 {}
		# It is fine to reference a task 2+ times
		task task2 task1, task1, task1
		# This is wrong, task1 is already defined
		task task1 {}
	}
}

# The tested task has three valid jobs and one invalid (42 ~ [int]).
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

# The tested task uses valid job type but its value is invalid.
task InvalidJobValue {
	Test "Add-BuildTask : Task '.': Hashtable task reference should have one item.*At *InvalidArgument*" {
		task . @(
			@{ task2 = 1; task1 = 1 }
		)
	}
}

# Incremental and Partial cannot be used together.
task IncrementalAndPartial {
	Test "Add-BuildTask : Task '.': Parameters Incremental and Partial cannot be used together.*At *InvalidArgument*" {
		task . -Incremental @{} -Partial @{} { throw 'Unexpected.' }
	}
}

# Invalid Incremental/Partial hashtable.
task IncrementalInvalidHashtable {
	Test "Add-BuildTask : Task '.': Invalid Incremental/Partial hashtable. Valid form: @{ Inputs = Outputs }.*At *InvalidArgument*" {
		task . -Incremental @{} { throw 'Unexpected.' }
	}
	Test "Add-BuildTask : Task '.': Invalid Incremental/Partial hashtable. Valid form: @{ Inputs = Outputs }.*At *InvalidArgument*" {
		task . -Partial @{} { throw 'Unexpected.' }
	}
}

# Example of a missing task. (Task preprocessing).
task TaskNotDefined {
	Test "*\Invoke-Build.ps1 : Task 'task1': Task 'missing' is not defined.*At *\z.build.ps1:2 *ObjectNotFound: (missing:String)*" {
		task task1 missing, {}
		task . task1, {}
	}
}

# Tasks with a cyclic reference: . -> task1 -> task2 -> task1 (oops!). (Task preprocessing).
task CyclicReference {
	Test "*\Invoke-Build.ps1 : Task 'task2': Cyclic reference to 'task1'.*At *\z.build.ps1:3 *InvalidOperation: (task1:String)*" {
		task task1 task2
		task task2 task1
		task . task1
	}
}

task . `
ScriptOutput,
TaskAddedTwice,
InvalidJobType,
InvalidJobValue,
IncrementalAndPartial,
IncrementalInvalidHashtable,
TaskNotDefined,
CyclicReference
