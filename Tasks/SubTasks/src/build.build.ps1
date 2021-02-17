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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([System.IO.Path]::GetFileName($MyInvocation.ScriptName) -ne 'Invoke-Build.ps1') {
	Invoke-Build -Task $Tasks -File $MyInvocation.MyCommand.Path @PSBoundParameters
	return
}

task task1 {
	"build task 1 $BuildParam1 $CommonChildParam"
}

task build-task2 {
	"build task 2 $BuildParam2 $CommonChildParam"
}

task . task1, build-task2
