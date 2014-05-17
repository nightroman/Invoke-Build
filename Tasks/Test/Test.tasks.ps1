
<#
.Synopsis
	Defines the custom task "test".

.Description
	Build scripts dot-source this script in order to use the task "test".

	Test-task parameters are Name, Jobs, If, Inputs, Outputs, and Partial.
	Jobs are optional simple references followed by a single action.

	If a test action fails then its error is counted and processed as usual but
	the build does not stop, so that other tests may work as well. If any of
	referenced tasks fail then the test action is skipped.

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
	$If=1,
	$Inputs,
	$Outputs,
	[switch]$Partial
)
{
	try {
		if (!$Jobs) {throw "Test-task must have an action job."}

		$action = $Jobs[-1]
		if ($action -isnot [scriptblock]) {throw "Test-task last job must be an action."}

		$tasks = @()
		$Jobs = @(
			# convert references to safe
			if ($Jobs.Length -ge 2) {
				foreach($j in $Jobs[0 .. ($Jobs.Length - 2)]) {
					if ($j -isnot [string]) {throw "Test-task jobs must be names followed by an action."}
					job $j -Safe
					$tasks += $j
				}
			}
			# the last job is the action
			{. Invoke-TestAction}
		)

		# wrapped task with data @{Task = referenced task names; Action = the original action}
		task $Name $Jobs -If:$If -Inputs:$Inputs -Outputs:$Outputs -Partial:$Partial -Source:$MyInvocation -Data:@{
			Tasks = $tasks
			Action = $action
		}
	}
	catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
}

# Invokes the current test action.
function Invoke-TestAction {
	# Check referenced task errors
	foreach($_ in $Task.Data.Tasks) {
		if (error $_) {
			Write-Build DarkGray 'Test skipped due to upstream errors.'
			return
		}
	}

	# Invoke the action, catch and set an error
	try {
		. $Task.Data.Action
	}
	catch {
		$Task.Error = $_
	}
}
