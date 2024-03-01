param(
	[Parameter(Position=0)]
	[string[]]$Tasks
	,
	[string]$BuildParam1
	,
	[string]$BuildParam2
	,
	[string]$CommonChildParam
)

if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
	$ErrorActionPreference = 1
	return Invoke-Build -Task $Tasks -File $MyInvocation.MyCommand.Path @PSBoundParameters
}

task task1 {
	"build task 1 $BuildParam1 $CommonChildParam"
}

task build-task2 {
	"build task 2 $BuildParam2 $CommonChildParam"
}

task . task1, build-task2
