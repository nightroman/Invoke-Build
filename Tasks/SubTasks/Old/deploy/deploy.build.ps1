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

if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
	$ErrorActionPreference=1
	return Invoke-Build -Task $Tasks -File $MyInvocation.MyCommand.Path @PSBoundParameters
}

task task1 {
	"deploy task 1 $DeployParam1 $CommonChildParam"
}

task deploy-task2 {
	"deploy task 2 $DeployParam2 $CommonChildParam"
}

task . task1, deploy-task2
