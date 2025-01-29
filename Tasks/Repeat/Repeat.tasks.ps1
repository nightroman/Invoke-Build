<#
.Synopsis
	Defines the custom task `repeat`.

.Description
	Build scripts dot-source this script in order to use the task `repeat`.

	A `repeat` task is invoked if the specified time is passed since the
	previous run. Otherwise it is skipped as if its `If` gets false.

	Task parameters:
		Normal: Name, Jobs, If, Inputs, Outputs, Partial
		Custom: Days, Hours, Minutes define a time span

	Script scope names:
		Alias: repeat
		Variables: RepeatClixml, RepeatData
		Functions: Add-Repeat, Test-Repeat, Complete-Repeat

.Parameter RepeatClixml
		Specifies the file path for saved data.
		Default: "$BuildFile.Repeat.clixml"

.Example
	>
	# Dot-source `repeat` definitions
	. <path>/Repeat.tasks.ps1

	# Add `repeat` tasks
	repeat RepeatSomething -Days 2 {
		...
	}
#>

param(
	$RepeatClixml = "$BuildFile.Repeat.clixml"
)

# Import data unless `WhatIf`.
if (!$WhatIf) {
	$RepeatData = if (Test-Path $RepeatClixml) {Import-Clixml $RepeatClixml} else {@{}}
}

# "DSL" for scripts.
Set-Alias repeat Add-Repeat

# Wrapper of `task` which adds a customized task used as `repeat`.
# Mind setting `Source` for error messages and help comments.
function Add-Repeat(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	[int]$Days,
	[int]$Hours,
	[int]$Minutes,
	$If=$true,
	$Inputs,
	$Outputs,
	[switch]$Partial
)
{
	# wrap task with new `If`, `Done`, `Source`, and required `Data`
	task $Name $Jobs -If:${function:Test-Repeat} -Done:Complete-Repeat -Source:$MyInvocation -Inputs:$Inputs -Outputs:$Outputs -Partial:$Partial -Data:@{
		If = $If
		Span = New-Object TimeSpan $Days, $Hours, $Minutes, 0
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
	if ($Task.Error) {return}
	$RepeatData[$Task.Name] = [DateTime]::Now
	$RepeatData | Export-Clixml $RepeatClixml
}
