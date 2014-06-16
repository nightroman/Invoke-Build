
<#
.Synopsis
	Defines the custom task "retry" and the function "Invoke-RetryAction".

.Description
	Build scripts dot-source this script in order to use the task "retry" or
	the function "Invoke-RetryAction".

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
	# Dot-source "retry" tools
	. <path>\Retry.tasks.ps1

	# Use "retry" tasks
	retry Task1 -RetryTimeout 10 -RetryInterval 2 {
		...
	}

	# Or use Invoke-RetryAction directly
	task Task2 {
		...
		Invoke-RetryAction 10 2 { ... }
		...
	}
#>

# New DSL word.
Set-Alias retry Add-RetryTask

<#
.Synopsis
	Invokes the action until it succeeds or the time is out.

.Description
	The action is repeated for the specified time until it succeeds.
	When the time is out the last error is re-thrown.

.Parameter RetryTimeout
		Total time for retrying, in seconds.
.Parameter RetryInterval
		Time to wait before trying again, in seconds.
.Parameter Action
		Specifies the action, a script block or a command name.
#>
function Invoke-RetryAction(
	[Parameter()][int]$RetryTimeout,
	[int]$RetryInterval,
	$Action
)
{
	${private:*RetryTimeout} = $RetryTimeout
	${private:*RetryInterval} = $RetryInterval
	${private:*Action} = $Action
	Remove-Variable RetryTimeout, RetryInterval, Action

	${private:*time} = [System.Diagnostics.Stopwatch]::StartNew()
	for() {
		try {
			. ${*Action}
			return
		}
		catch {
			if (${*time}.Elapsed.TotalSeconds -gt ${*RetryTimeout}) {throw}
			Write-Build Yellow "$($Task.Name) error: $_"
			"Waiting for ${*RetryInterval} seconds..."
			Start-Sleep -Seconds ${*RetryInterval}
			"Retrying..."
		}
	}
}

# Wrapper of "task" which adds a customized task used as "retry".
# Mind setting "Source" for error messages and help comments.
function Add-RetryTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	$If=$true,
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
				{
					$_ = $Task.Data
					. Invoke-RetryAction @_
				}
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
