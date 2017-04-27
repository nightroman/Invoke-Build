
<#
.Synopsis
	Defines the custom task "test".

.Description
	Build scripts dot-source this script in order to use the task "test".

	A test-task has a single action, the test. If this action fails then the
	task error is counted and processed as usual but the build does not stop,
	so that other tests may work. A test-task may reference other tests, too.
	References are checked for errors. If there is any the action is skipped
	and the error is propagated.

	Test-task parameters:
		Name, If, Inputs, Outputs - as usual
		Jobs - as usual but with a single action

	Script scope names:
		Alias: test
		Functions: Add-TestTask, Invoke-TestAction

.Example
	>
	# Dot-source "test" definitions
	. [<path>]Test.tasks.ps1

	# Add "test" tasks
	test TestSomething {
		...
	}
#>

# New DSL word.
Set-Alias test Add-TestTask

# Wrapper of "task" which adds a customized task used as "test".
# Mind setting "Source" for error messages and help comments.
function Add-TestTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	$If=$true,
	$Inputs,
	$Outputs
)
{
	trap {$PSCmdlet.ThrowTerminatingError($_)}

	# wrap an action
	$action = $null
	$Jobs = foreach($j in $Jobs) {
		if ($j -isnot [scriptblock]) {
			$j
		}
		elseif ($action) {
			throw 'Test-task cannot have two action jobs.'
		}
		else {
			$action = $j
			{. Invoke-TestAction}
		}
	}

	# wrapped task with data = the original action
	task $Name $Jobs -If:$If -Inputs:$Inputs -Outputs:$Outputs -Source:$MyInvocation -Data:$action
}

# Invokes the current test action.
function Invoke-TestAction {
	# Check referenced task errors
	foreach($_ in $Task.Jobs) {
		if ($_ -is [string] -and (error $_)) {
			$Task.Error = error $_
			return
		}
	}

	# Invoke the action, catch and set an error
	try {
		. $Task.Data
	}
	catch {
		$Task.Error = $_
	}
}
