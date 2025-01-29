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
		Functions: New-Repeat, Test-Repeat, Complete-Repeat -- used internally

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

# Import data unless `WhatIf`.
if (!$WhatIf) {
	$RepeatData = if (Test-Path -LiteralPath $RepeatClixml) {Import-Clixml -LiteralPath $RepeatClixml} else {@{}}
}

# "DSL" for scripts.
Set-Alias repeat New-Repeat

# Creates the custom task parameters.
function New-Repeat(
	[Parameter(Position=0)][object[]]$Jobs,
	$If=$true,
	[int]$Days,
	[int]$Hours,
	[int]$Minutes
)
{
	@{
		Jobs = $Jobs
		If = ${function:Test-Repeat}
		Done = ${function:Complete-Repeat}
		Data = @{If = $If; Span = [timespan]::new($Days, $Hours, $Minutes, 0)}
	}
}

# Works as tasks `If`. The original condition is processed first.
# If it is true then the task last done time is tested.
function Test-Repeat {
	$_ = $Task.Data.If
	if ($_ -is [scriptblock]) {
		$_ = & $_
	}

	if ($_) {
		$date = $RepeatData[$Task.Name]
		!$date -or (([DateTime]::Now - $date) -gt $Task.Data.Span)
	}
}

# Works as tasks `Done`. It saves the task done time.
function Complete-Repeat {
	if (!$Task.Error) {
		$RepeatData[$Task.Name] = [DateTime]::Now
		$RepeatData | Export-Clixml -LiteralPath $RepeatClixml
	}
}
