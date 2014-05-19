
<#
.Synopsis
	Defines the custom task "check".

.Description
	Build scripts dot-source this script in order to use the task "check".

	The build file with checks represents a check-list and checks are normally
	invoked together (*). But they can be invoked individually, too. Tasks can
	reference checks. Checks can reference tasks.

	In other words, checks are normal tasks with an extra feature: as soon as a
	check is passed, it is never checked again, even in builds invoked after.

	Check-task parameters are Name, Jobs, Inputs, Outputs, and Partial.
	If and Done are already used for the definition of "check".

	Script scope names:
		Alias: check
		Variables: CheckClixml, CheckData
		Functions: Add-CheckTask, Test-CheckTask, Set-CheckDone

.Parameter CheckClixml
		Specifies the file where passed checks are stored.
		Default: "$BuildFile.Check.clixml"

.Example
	>
	# Dot-source "check" definitions
	. [<path>]Check.tasks.ps1

	# Add "check" tasks
	check CheckSomething {
		...
	}
#>

param(
	$CheckClixml = "$BuildFile.Check.clixml"
)

# New DSL word.
Set-Alias check Add-CheckTask

# Wrapper of "task" which adds a customized task used as "check".
# Mind setting "Source" for error messages and help comments.
function Add-CheckTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	$Inputs,
	$Outputs,
	[switch]$Partial
)
{
	task $Name $Jobs -If:{Test-CheckTask} -Done:Set-CheckDone -Source:$MyInvocation -Inputs:$Inputs -Outputs:$Outputs -Partial:$Partial
}

# This function is called as If for custom tasks.
function Test-CheckTask {
	!$CheckData[$Task.Name]
}

# This function is called as Done for custom tasks.
# For the current task it stores its done time.
# Then it writes all information to the file.
function Set-CheckDone {
	$CheckData[$Task.Name] = [DateTime]::Now
	$CheckData | Export-Clixml $CheckClixml
}

# Import information about passed tasks from the file.
# Note that this action is skipped in WhatIf mode.
if (!$WhatIf) {
	$CheckData = if (Test-Path $CheckClixml) {Import-Clixml $CheckClixml} else {@{}}
}
