
<#
.Synopsis
	Defines the custom task "file".

.Description
	Build scripts dot-source this script in order to use the task "file".

	A file-task is a task with simplified syntax similar to Rake "file". Inputs
	and Outputs are mandatory positional parameters, the names may be omitted.

	File-task parameters:
		Name, Jobs, If, Partial, Data, Done, Source - as usual
		Inputs, Outputs - as usual but mandatory positional

	Script scope names:
		Alias: file
		Function: Add-FileTask

.Example
	>
	# Dot-source "file" definitions
	. <path>\File.tasks.ps1

	# Add "file" tasks
	file Task1 <inputs> <outputs> {
		...
	}
#>

# New DSL word.
Set-Alias file Add-FileTask

# Wrapper of "task" which adds a customized task used as "file".
# Mind setting "Source" for error messages and help comments.
function Add-FileTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1, Mandatory=1)]$Inputs,
	[Parameter(Position=2, Mandatory=1)]$Outputs,
	[Parameter(Position=3)][object[]]$Jobs,
	$If=1,
	$Data,
	$Done,
	$Source = $MyInvocation,
	[switch]$Partial
)
{
	task @PSBoundParameters
}
