<#
.Synopsis
	Example root build script with sub tasks in child scripts.

.Parameter Tasks
		Specifies root tasks or special `build` or `deploy`.
.Parameter SubTasks
		When `build` or `deploy`, specifies child tasks.
.Parameter RootParam1
		Some parameter for root tasks.
#>

param(
	[Parameter(Position=0)]
	[string[]]$Tasks
	,
	[Parameter(Position=1)]
	[ArgumentCompleter({
		param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
		$Tasks = $fakeBoundParameters['Tasks']
		if ($Tasks) {
			$map = @{deploy='deploy/deploy.build.ps1'; build='src/build.build.ps1'}
			foreach($_ in $Tasks) {
				$file = $map[$_]
				if ($file) {
					(Invoke-Build ?? $file).get_Keys()
				}
			}
		}
	})]
	[string[]]$SubTasks
	,
	[string]$RootParam1
)

dynamicparam {
	$DP = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	$Tasks = $PSBoundParameters['Tasks']
	if (!$Tasks) {
		$Tasks = $PSCmdlet.GetVariableValue('DynamicParamTasks')
	}
	if ($Tasks) {
		$skip = 'Tasks', 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'ErrorVariable', 'WarningVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'InformationAction', 'InformationVariable', 'ProgressAction'
		$map = @{deploy='deploy/deploy.build.ps1'; build='src/build.build.ps1'}
		foreach($_ in $Tasks) {
			$file = $map[$_]
			if ($file) {
				$params = (Get-Command $file).Parameters
				foreach($p in $params.get_Values()) {
					if ($skip -notcontains $p.Name) {
						$DP[$p.Name] = New-Object System.Management.Automation.RuntimeDefinedParameter $p.Name, $p.ParameterType, $p.Attributes
					}
				}
			}
		}
	}
	$DP
}

end {
	Set-StrictMode -Version Latest
	$ErrorActionPreference = 'Stop'

	# Bootstrap and call Invoke-Build
	if ([System.IO.Path]::GetFileName($MyInvocation.ScriptName) -ne 'Invoke-Build.ps1') {
		# bootstrap (omitted)
		# ...

		#! for dynamic parameters
		$DynamicParamTasks = $Tasks

		# call Invoke-Build
		Invoke-Build -Task $Tasks -File $MyInvocation.MyCommand.Path @PSBoundParameters
		return
	}

	# remove SubTasks, it does not exist in child scripts
	$MyParameters = $PSBoundParameters
	$null = $MyParameters.Remove("SubTasks")

	# Synopsis: Just delegates to src/build.build.ps1
	task build {
		Invoke-Build -Task $SubTasks -File src/build.build.ps1 @MyParameters
	}

	# Synopsis: Just delegates to deploy/deploy.build.ps1
	task deploy {
		Invoke-Build -Task $SubTasks -File deploy/deploy.build.ps1 @MyParameters
	}

	# Synopsis: Top level task.
	task root {
		"root task $RootParam1"
	}

	task . root
}
