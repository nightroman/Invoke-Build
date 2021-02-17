param(
	[Parameter(Position=0)]
	[string[]]$Tasks
	,
	[string]$DeployParam1
	,
	[string]$DeployParam2
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
	"deploy task 1 $DeployParam1 $CommonChildParam"
}

task deploy-task2 {
	"deploy task 2 $DeployParam2 $CommonChildParam"
}

task . task1, deploy-task2
