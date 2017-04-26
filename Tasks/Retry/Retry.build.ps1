
<#
.Synopsis
	Example of retry-tasks.

.Description
	This script is a demo of the custom retry-task.
	See "Retry.tasks.ps1" for the details of "retry".

.Example
	Invoke-Build * Retry.build.ps1
#>

# Import retry-task tools.
. .\Retry.tasks.ps1
. .\RetryNr.tasks.ps1

$RetryWorks = $false

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
		$script:RetryWorks = $true
		throw "It fails."
	}
}

# Synopsis: This retry-task always fails. It is referenced by another task.
retry RetryFails -RetryTimeout 4 -RetryInterval 2 {
	throw "It fails."
}

# Synopsis: A task with a safe reference to a retry-task.
task CallRetryFails (job RetryFails -Safe)

# Synopsis: A task uses Invoke-RetryAction directly.
task InvokeRetryAction {
	# before the action started
	"Before the action"

	# invoke the action
	$script:RetryWorks = $false
	Invoke-RetryAction 10 2 {
		if ($RetryWorks) {
			"It works."
		}
		else {
			$script:RetryWorks = $true
			throw "It fails."
		}
	}

	# after the action succeeded
	"After the action"
}

# Synopsis: A task uses Inovke-RetryNrAction directly.
task InvokeRetryNrAction {
	# before the action started
	"Before the action"

	# invoke the action
	$script:RetryWorks = $false
	Invoke-RetryNrAction 1 5 {
		if ($RetryWorks) {
			"It works."
		}
		else {
			$script:RetryWorks = $true
			throw "It fails."
		}
	}

	# after the action succeeded
	"After the action"
}

# Synopsis: This retrynr-task always fails. It is referenced by another task.
retrynr RetryNrFails -RetryCount 5 -RetryInterval 1 {
	throw "It fails."
}

# Synopsis: A task with a safe reference to a retrynr-task.
task CallRetryNrFails (job RetryNrFails -Safe)
