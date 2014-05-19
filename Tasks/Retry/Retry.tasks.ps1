
<#
.Synopsis
	Defines the custom task "retry".

.Description
	Build scripts dot-source this script in order to use the task "retry".

	A retry-task should have a single action which is repeated until it
	succeeds or timed out. Incremental task parameters are not supported.

	Retry-task parameters:
		Name, If - as usual
		Jobs - as usual but with a single action
		RetryTimeout - [int], total retry time in seconds
		RetryInterval - [int], wait time after failures in seconds

	Script scope names:
		Alias: retry
		Functions: Add-RetryTask, Invoke-RetryAction

.Example
	>
	# Dot-source "retry" definitions
	. [<path>]Retry.tasks.ps1

	# Add "retry" tasks
	retry RetrySomething -RetryTimeout 10 -RetryInterval 2 {
		...
	}
#>

# New DSL word.
Set-Alias retry Add-RetryTask

# Wrapper of "task" which adds a customized task used as "retry".
# Mind setting "Source" for error messages and help comments.
function Add-RetryTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	$If=1,
	[int]$RetryInterval,
	[int]$RetryTimeout
)
{
	try {
		if (!$Jobs) {throw 'Retry-task must have an action.'}

		$action = $null
		$Jobs = foreach($j in $Jobs) {
			if ($j -isnot [scriptblock]) {
				$j
			}
			elseif ($action) {
				throw 'Retry-task cannot have two actions.'
			}
			else {
				$action = $j
				{. Invoke-RetryAction}
			}
		}
		if (!$action) {
			throw 'Retry-task must have an action.'
		}

		# wrapped task with data @{Action = the original action; RetryCount}
		task $Name $Jobs -If:$If -Source:$MyInvocation -Data:@{
			RetryInterval = $RetryInterval
			RetryTimeout = $RetryTimeout
			Action = $action
		}
	}
	catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
}

# Invokes the current retry action.
function Invoke-RetryAction {
	${private:**time} = [System.Diagnostics.Stopwatch]::StartNew()
	for() {
		try {
			. $Task.Data.Action
			break
		}
		catch {
			if (${**time}.Elapsed.TotalSeconds -gt $Task.Data.RetryTimeout) {throw}
			Write-Build Yellow "$($Task.Name) error: $_"
			"Waiting for $($Task.Data.RetryInterval) seconds..."
			Start-Sleep -Seconds $Task.Data.RetryInterval
		}
	}
}
