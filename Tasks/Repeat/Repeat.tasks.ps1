
<#
.Synopsis
	Defines the custom task "repeat".

.Description
	Build scripts dot-source this script in order to use the task "repeat".

	The build file with repeats represents a schedule and repeats are normally
	invoked together (*). But they can be invoked individually, too. Tasks can
	reference repeats. Repeats can reference tasks.

	In other words, repeats are normal tasks with an extra feature: they are
	invoked only if specified time intervals are passed since previous runs.

	Repeat-task parameters are Name, Jobs, Inputs, Outputs, and Partial.
	If and Done are already used for the definition of "repeat".
	Additional parameters Days, Hours, Minutes define a span.

	Script scope names:
		Alias: repeat
		Variables: RepeatClixml, RepeatData
		Functions: Add-RepeatTask, Test-RepeatTask, Set-RepeatDone

.Parameter RepeatClixml
		Specifies the file where passed repeats are stored.
		Default: "$BuildFile.Repeat.clixml"

.Example
	>
	# Dot-source "repeat" definitions
	. [<path>]Repeat.tasks.ps1

	# Add "repeat" tasks
	repeat RepeatSomething -Days 2 {
		...
	}
#>

param(
	$RepeatClixml = "$BuildFile.Repeat.clixml"
)

# New DSL word.
Set-Alias repeat Add-RepeatTask

# Wrapper of "task" which adds a customized task used as "repeat".
# Mind setting "Source" for error messages and help comments.
function Add-RepeatTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	[int]$Days,
	[int]$Hours,
	[int]$Minutes,
	$Inputs,
	$Outputs,
	[switch]$Partial
)
{
	task $Name $Jobs -If:{Test-RepeatTask} -Done:Set-RepeatDone -Source:$MyInvocation -Inputs:$Inputs -Outputs:$Outputs -Partial:$Partial -Data (
		New-Object TimeSpan $Days, $Hours, $Minutes, 0
	)
}

# This function is called as If for custom tasks.
function Test-RepeatTask {
	$date = $RepeatData[$Task.Name]
	!$date -or (([DateTime]::Now - $date) -gt $Task.Data)
}

# This function is called as Done for custom tasks.
# For the current task it stores its done time.
# Then it writes all information to the file.
function Set-RepeatDone {
	$RepeatData[$Task.Name] = [DateTime]::Now
	$RepeatData | Export-Clixml $RepeatClixml
}

# Import information about passed tasks from the file.
# Note that this action is skipped in WhatIf mode.
if (!$WhatIf) {
	$RepeatData = if (Test-Path $RepeatClixml) {Import-Clixml $RepeatClixml} else {@{}}
}
