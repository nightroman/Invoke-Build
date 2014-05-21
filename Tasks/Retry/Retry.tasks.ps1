
<#
.Synopsis
	Defines the custom task "retry".

.Description
	Build scripts dot-source this script in order to use the task "retry".

	A retry-task has a single action. This action is repeated for the specified
	time until it succeeds. When the time is out the last error is re-thrown.

	Retry-task parameters:
		Name, If, Inputs, Outputs - as usual
		Jobs - as usual but with a single action
		RetryTimeout - [int], seconds, total time for retrying
		RetryInterval - [int], seconds, time to wait before trying again

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
	$Inputs,
	$Outputs,
	[int]$RetryTimeout,
	[int]$RetryInterval
)
{
	try {
		# wrap an action
		$action = $null
		$Jobs = foreach($j in $Jobs) {
			if ($j -isnot [scriptblock]) {
				$j
			}
			elseif ($action) {
				throw 'Retry-task cannot have two action jobs.'
			}
			else {
				$action = $j
				{. Invoke-RetryAction}
			}
		}

		# wrap a task with data @{Action = the original action; Retry* = extra parameters}
		task $Name $Jobs -If:$If -Inputs:$Inputs -Outputs:$Outputs -Source:$MyInvocation -Data:@{
			Action = $action
			RetryTimeout = $RetryTimeout
			RetryInterval = $RetryInterval
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
			"Retrying..."
		}
	}
}
