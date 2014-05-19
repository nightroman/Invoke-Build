
<#
.Synopsis
	Example of retry-tasks.

.Description
	This script is a demo of the custom retry-task.
	See "Retry.tasks.ps1" for the details of "retry".

.Example
	Invoke-Build * Retry.build.ps1
#>

# Import retry-task definitions.
. .\Retry.tasks.ps1

$RetryWorks = 0

# Synopsis: A task referenced by a retry-task.
task JustTask {
	'In JustTask.'
}

# Synopsis: Retry-task works after a failure. It also references another task.
retry RetryWorks -RetryTimeout 10 -RetryInterval 2 JustTask, {
	if ($RetryWorks) {
		"It works."
	}
	else {
		$script:RetryWorks = 1
		throw "It fails."
	}
}

# Synopsis: Retry-task always fails. It is referenced by another task.
retry RetryFails -RetryTimeout 4 -RetryInterval 2 {
	throw "It fails."
}

# Synopsis: A task with a safe reference to a retry-task.
task CallRetryFails (job RetryFails -Safe)
