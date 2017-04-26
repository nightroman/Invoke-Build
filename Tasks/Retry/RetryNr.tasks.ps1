
<#
.Synopsis
	Defines the custom task "retrynr" and the function "Invoke-RetryNrAction".

.Description
	Build scripts dot-source this script in order to use the task "retrynr" or
	the function "Invoke-RetryNrAction".

	A retry-task has a single action. This action is repeated for the specified
	time until it succeeds. When the time is out the last error is re-thrown.

	Retry-task parameters:
		Name, If, Inputs, Outputs - as usual
		Jobs - as usual but with a single action
		RetryCount - [int], number of retries
		RetryInterval - [int], seconds, time to wait before trying again

	Script scope names:
		Alias: retrynr
		Functions: Add-RetryNrTask, Invoke-RetryNrAction

.Example
	>
	# Dot-source "retrynr" tools
	. <path>\RetryNr.tasks.ps1

	# Use "retrynr" tasks
	retrynr Task1 -RetryCount 2 -RetryInterval 10 {
		...
	}

	# Or use Invoke-RetryAction directly
	task Task2 {
		...
		Invoke-RetryAction 2 10 { ... }
		...
	}
#>

# New DSL word.
Set-Alias retrynr Add-RetryNrTask

<#
.Synopsis
	Invokes the action until it succeeds or max RetryCount times.

.Description
	The action is repeated n times (n=RetryCount) or until it succeeds.
	The last error is re-thrown.

.Parameter RetryCount
		Total number of tries before failing
.Parameter RetryInterval
		Time to wait before trying again, in seconds.
.Parameter Action
		Specifies the action, a script block or a command name.
#>
function Invoke-RetryNrAction(
	[Parameter()][int]$RetryCount,
	[int]$RetryInterval,
	$Action
)
{
	${private:*RetryCount} = $RetryCount
	${private:*RetryInterval} = $RetryInterval
	${private:*Action} = $Action
	Remove-Variable RetryCount, RetryInterval, Action
	
	for(;;${*RetryCount}--) {
		try {
			. ${*Action}
			return
		}
		catch {
			if (${*RetryCount} -le 0) {throw}
			Write-Build Yellow "$($Task.Name) error: $_"
			"Waiting for ${*RetryInterval} seconds..."
			Start-Sleep -Seconds ${*RetryInterval}
			"Retrying... (${*RetryCount} retries left)"
		}
	}
}

# Wrapper of "task" which adds a customized task used as "retrynr".
# Mind setting "Source" for error messages and help comments.
function Add-RetryNrTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	$If=$true,
	$Inputs,
	$Outputs,
	[int]$RetryCount,
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
				throw 'RetryNr-task cannot have two action jobs.'
			}
			else {
				$action = $j
				{
					$_ = $Task.Data
					. Invoke-RetryNrAction @_
				}
			}
		}

		# wrap a task with data @{Action = the original action; Retry* = extra parameters}
		task $Name $Jobs -If:$If -Inputs:$Inputs -Outputs:$Outputs -Source:$MyInvocation -Data:@{
			Action = $action
			RetryCount = $RetryCount
			RetryInterval = $RetryInterval
		}
	}
	catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
}
