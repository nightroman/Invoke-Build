
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

# Synopsis: A task referenced by a retry-task.
task JustTask {
	'In JustTask.'
}

# Synopsis: Retry-task works after a failure. It also references another task.
retry RetryWorks -RetryTimeout 10 -RetryInterval 2 JustTask, {
	if (++$script:RetryWorks -le 1) {
		throw "It fails."
	}
	"It works."
}
$RetryWorks = 0

# Synopsis: This retry-task always fails. It is referenced by another task.
retry RetryFails -RetryTimeout 4 -RetryInterval 2 {
	throw "It fails."
}

# Synopsis: Safe RetryFails for testing.
task SafeRetryFails ?RetryFails

# Synopsis: A task uses Invoke-RetryAction directly.
task InvokeRetryAction {
	# before the action started
	"Before the action"

	# invoke the action, it fails once then works
	$script:InvokeRetryAction = 0
	Invoke-RetryAction -RetryTimeout 10 -RetryInterval 2 {
		if (++$script:InvokeRetryAction -le 1) {
			throw "It fails."
		}
		"It works."
	}

	# after the action succeeded
	"After the action"
}

# Synopsis: Test RetryCount with final success.
# The action fails 2 times. We allow 2 retries. As a result, the task works.
retry RetryCountWorks -RetryCount 2 -RetryInterval 2 {
	if (++$script:RetryCountWorks -le 2) {
		throw "It fails."
	}
	"It works"
}
$RetryCountWorks = 0

# Synopsis: Test RetryCount with final failure.
# The action keeps failing. We allow 2 retries. As a result, the task fails.
retry RetryCountFails -RetryCount 2 -RetryInterval 2 {
	throw "It fails."
}

# Synopsis: Safe RetryCountFails for testing.
task SafeRetryCountFails ?RetryCountFails

# Synopsis: Retry with both count and time limits. It fails due to count.
retry CountAndTimeFailByCount -RetryCount 2 -RetryTimeout 100 -RetryInterval 2 {
	throw "It fails."
}

# Synopsis: Safe CountAndTimeFailByCount for testing.
task SafeCountAndTimeFailByCount ?CountAndTimeFailByCount

# Synopsis: Retry with both count and time limits. It fails due to timeout.
retry CountAndTimeFailByTime -RetryCount 100 -RetryTimeout 10 -RetryInterval 2 {
	throw "It fails."
}

# Synopsis: Safe CountAndTimeFailByTime for testing.
task SafeCountAndTimeFailByTime ?CountAndTimeFailByTime
