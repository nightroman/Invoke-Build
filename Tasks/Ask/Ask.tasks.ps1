
<#
.Synopsis
	Defines the custom task `ask`.

.Description
	The script defines the custom task `ask` which asks for the confirmation.
	If a user chooses "No" then the task is skipped as if its `If` parameter
	gets false, i.e. together with referenced tasks.

	Note that an ask-task may have usual task parameters, including its own `If`.
	When the original `If` gets false then the task is skipped without asking.

	Extra ask-task parameters:
		Prompt: optional [string], the custom message printed on confirmation.

	Script scope names:
		Alias: ask
		Functions: Add-AskTask, Test-AskTask

.Example
	>
	# Dot-source `ask` tools
	. <path>/Ask.tasks.ps1

	# Trivial ask-task with the default prompt
	ask AddSugar {
		...
	}

	# Ask-task with a prompt and another task
	ask MakeTea -Prompt 'Make some tea?' AddSugar, {
		...
	}
#>

# New DSL word.
Set-Alias ask Add-AskTask

# Asks for task confirmation.
function Test-AskTask {
	[CmdletBinding(SupportsShouldProcess=1, ConfirmImpact='High')] param()
	$prompt = $Task.Data.Prompt
	$caption = "Task $($Task.Name)"
	$PSCmdlet.ShouldProcess($prompt, $prompt, $caption)
}

# Wrapper of `task` which adds a customized task used as `ask`.
# Mind setting `Source` for error messages and help comments.
function Add-AskTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	[string]$Prompt='',
	$If=$true,
	$Inputs,
	$Outputs,
	[switch]$Partial
)
{
	# amend `If`
	$newIf = {
		# process the original `If`
		$_ = $Task.Data.If
		if ($_ -is [scriptblock]) {
			$_ = & $_
		}
		# ask unless `If` is false
		if ($_) {
			Test-AskTask
		}
	}

	# task with the new `If` and the data for it
	task $Name $Jobs -If:$newIf -Inputs:$Inputs -Outputs:$Outputs -Partial:$Partial -Source:$MyInvocation -Data:@{
		If = $If
		Prompt = $Prompt
	}
}
