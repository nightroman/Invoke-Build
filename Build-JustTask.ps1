<#
.Synopsis
	Builds just the specified tasks skipping referenced tasks.
	Copyright (c) Roman Kuzmin

.Description
	The script invokes Invoke-Build with the usual parameters, with at least
	one task specified explicitly. The specified tasks are invoked without
	their referenced tasks. This unusual scenario may be useful in special
	cases like debugging or development of a particular task when its
	referenced tasks are completed and may be safely skipped.

	Not every task may be correctly invoked in this way. If referenced tasks
	configure the build environment and variables then they must be invoked.
#>

param(
	[Parameter(Position=0, Mandatory=1)]
	[string[]]$Task
	,
	[Parameter(Position=1)]$File
	,
	[switch]$Safe
	,
	[switch]$Summary
)

$ErrorActionPreference=1
try {
	${*data} = @{
		Task = $Task
		XBuild = {
			$tasks = ${*data}.Task
			foreach($_ in ${*}.All.get_Values()) {
				if ($tasks -notcontains $_.Name) {
					$_.If = 0
				}
			}
		}
	}

	Remove-Variable Task, File, Safe, Summary
	Invoke-Build @PSBoundParameters -Result ${*data}
}
catch {
	if ($_.InvocationInfo.ScriptName -notmatch '\b(Invoke-Build|Build-JustTask)\.ps1$') {throw}
	$PSCmdlet.ThrowTerminatingError($_)
}
