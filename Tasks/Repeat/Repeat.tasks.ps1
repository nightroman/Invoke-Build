
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
		Functions: Add-RepeatTask, Test-RepeatTask, Set-RepeatDone

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

# New DSL word.
Set-Alias repeat Add-RepeatTask

# Wrapper of `task` which adds a customized task used as `repeat`.
# Mind setting `Source` for error messages and help comments.
function Add-RepeatTask(
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
	task $Name $Jobs -If:{Test-RepeatTask} -Done:Set-RepeatDone -Source:$MyInvocation -Inputs:$Inputs -Outputs:$Outputs -Partial:$Partial -Data:@{
		If = $If
		Span = New-Object TimeSpan $Days, $Hours, $Minutes, 0
	}
}

# This function is called as `If`.
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

# This function is called as `Done`. It saves the current task time.
function Set-RepeatDone {
	if ($Task.Error) {return}
	$RepeatData[$Task.Name] = [DateTime]::Now
	$RepeatData | Export-Clixml $RepeatClixml
}

# Import data unless `WhatIf`.
if (!$WhatIf) {
	$RepeatData = if (Test-Path $RepeatClixml) {Import-Clixml $RepeatClixml} else {@{}}
}
