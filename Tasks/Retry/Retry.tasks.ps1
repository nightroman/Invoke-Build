
<#
.Synopsis
	Defines the custom task "retry" and the function "Invoke-RetryAction".

.Description
	Build scripts dot-source this script in order to use the task "retry" or
	the function "Invoke-RetryAction".

	A retry-task has a single action. This action is repeated the specified
	number of times or for the specified time until it succeeds. When the
	retry count or time is out the last error is re-thrown.

	If the parameters RetryCount and RetryTimeout are both defined (positive)
	then the action is repeated until one of these conditions is out.

	Retry-task parameters:
		Name, If, Inputs, Outputs - as usual
		Jobs - as usual but with a single action
		RetryCount - [int], total number of tries
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
		Invoke-RetryAction -RetryCount 3 -RetryInterval 2 { ... }
		...
	}
#>

# New DSL word.
Set-Alias retry Add-RetryTask

<#
.Synopsis
	Invokes the action and retries on failures.

.Description
	The action is repeated on failures the specified number of times or for the
	specified time. When the retry count or time is out the last error is
	re-thrown.

	If the parameters RetryCount and RetryTimeout are both defined (positive)
	then the action is repeated until one of these conditions is out.

.Parameter Action
		Specifies the action, a script block or a command name.
		The parameter name is optional.
.Parameter RetryCount
		Total number of tries before failing.
.Parameter RetryTimeout
		Total time for retrying, in seconds.
.Parameter RetryInterval
		Time to wait before trying again, in seconds.
#>
function Invoke-RetryAction(
	[Parameter(Position=0, Mandatory=1)]$Action,
	[int]$RetryCount,
	[int]$RetryTimeout,
	[int]$RetryInterval
)
{
	${private:*Action} = $Action
	${private:*RetryCount} = $RetryCount
	${private:*RetryTimeout} = $RetryTimeout
	${private:*RetryInterval} = $RetryInterval
	Remove-Variable Action, RetryCount, RetryTimeout, RetryInterval

	${private:*time} = [System.Diagnostics.Stopwatch]::StartNew()
	${private:*count} = ${*RetryCount}
	for() {
		try {
			. ${*Action}
			return
		}
		catch {
			# no retry
			if (${*RetryCount} -le 0 -and ${*RetryTimeout} -le 0) {throw}

			# count is out
			if (${*RetryCount} -gt 0 -and --${*count} -lt 0) {throw}

			# time is out
			if (${*RetryTimeout} -gt 0 -and ${*time}.Elapsed.TotalSeconds -gt ${*RetryTimeout}) {throw}

			# wait and retry
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
	[int]$RetryCount,
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
			RetryCount = $RetryCount
			RetryTimeout = $RetryTimeout
			RetryInterval = $RetryInterval
		}
	}
	catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
}
