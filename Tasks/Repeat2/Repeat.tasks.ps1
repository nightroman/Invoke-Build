<#
.Synopsis
	Defines the custom task parameters `repeat`.

.Description
	Build scripts dot-source this script in order to use `repeat`.

	A repeat-task is invoked if the specified time is passed since the
	previous run. Otherwise it is skipped as if its `If` gets false.

	Parameters:
		task:
			- Name, Inputs, Outputs, Partial
		repeat:
			- Jobs, If ~ moved from task
			- Days, Hours, Minutes ~ define a time span

	Script scope names:
		Alias: repeat -- used in repeat-tasks parameters
		Variables: RepeatClixml, RepeatData -- used internally
		Functions: New-RepeatParameters, Test-RepeatTask, Set-RepeatDone -- used internally

.Parameter RepeatClixml
		Specifies the file path for saved data.
		Default: "$BuildFile.Repeat.clixml"

.Example
	>
	# Dot-source `repeat` definitions
	. <path>/Repeat.tasks.ps1

	# Add `repeat` tasks
	task RepeatSomething (repeat -Days 2 {
		...
	})
#>

param(
	$RepeatClixml = "$BuildFile.Repeat.clixml"
)

# New DSL word.
Set-Alias repeat New-RepeatParameters

# Creates the custom task parameters.
function New-RepeatParameters(
	[Parameter(Position=0)][object[]]$Jobs,
	$If=$true,
	[int]$Days,
	[int]$Hours,
	[int]$Minutes
)
{
	@{
		Jobs = $Jobs
		If = {Test-RepeatTask}
		Done = {Set-RepeatDone}
		Data = @{
			If = $If
			Span = [timespan]::new($Days, $Hours, $Minutes, 0)
		}
	}
}

# This function is called as the current task `If`.
function Test-RepeatTask {
	# process the original `If`
	$_ = $Task.Data.If
	if ($_ -is [scriptblock]) {
		$_ = & $_
	}

	# check the span unless `If` is false
	if ($_) {
		$date = $RepeatData[$Task.Name]
		!$date -or (([DateTime]::Now - $date) -gt $Task.Data.Span)
	}
}

# This function is called as the current task `Done`. It saves the task time.
function Set-RepeatDone {
	if (!$Task.Error) {
		$RepeatData[$Task.Name] = [DateTime]::Now
		$RepeatData | Export-Clixml -LiteralPath $RepeatClixml
	}
}

# Import data unless `WhatIf`.
if (!$WhatIf) {
	$RepeatData = if (Test-Path -LiteralPath $RepeatClixml) {Import-Clixml -LiteralPath $RepeatClixml} else {@{}}
}
