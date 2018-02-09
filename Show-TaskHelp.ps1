
<#
.Synopsis
	Shows Invoke-Build task help information.
	Copyright (c) Roman Kuzmin

.Description
	The command shows the specified tasks help information as task names with
	synopses, jobs with their locations, script parameters and environment. By
	default, it analyses the code in order to extract variables in addition to
	optionally documented in comments.

	Synopsis is defined in task comments as # Synopsis: ...
	Parameters are defined as # Parameters: name1, name2, ...
	Environment variables are defined as # Environment: name1, name2, ...

	Parameters names match build parameters and separated by spaces or commas.
	Parameter descriptions are taken from the build script comment based help.

	Help info members (for custom formatters):

		Task: [object[]] Tasks to do.
			Name: [string] Task name.
			Synopsis: [string] Task synopsis, may be null.
		Jobs: [object[]] Jobs to do.
			Name: [string] Task name.
			Location: [string] Task location as "<file>:<line>".
		Parameters: [object[]] Tasks parameters, may be empty.
			Name: [string] Parameter name.
			Type: [string] Parameter type.
			Description: [string] Parameter help, may be null or empty.
		Environment: [string[]] Tasks environment variables, may be empty.

.Parameter Task
		Build task name(s). The default is the usual default task.
.Parameter File
		Build script path. The default is the usual default script.
.Parameter NoCode
		Tells to skip code analysis for parameters and environment.
		It is used as true for PowerShell v2.
.Parameter Format
		Specifies the custom task help formatter.

.Link
	https://github.com/nightroman/Invoke-Build
#>

param(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)]$File,
	$Format = 'Format-TaskHelp',
	[switch]$NoCode
)

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 1

if ([System.IO.Path]::GetFileName($MyInvocation.ScriptName) -eq 'Invoke-Build.ps1') {
	$all = ${*}.All
	Remove-Variable Task
}
else {
	$BuildTask = $Task
	$BuildFile = $File
	. Invoke-Build

	### resolve file
	if ($BuildFile) {
		$BuildFile = *Path $BuildFile
		if (![System.IO.File]::Exists($BuildFile)) {*Fin "Missing file '$BuildFile'." 5}
	}
	else {
		$BuildFile = Get-BuildFile (*Path)
		if (!$BuildFile) {*Fin 'Missing default script.' 5}
	}

	### resolve task
	$all = Invoke-Build ?? $BuildFile
	if (!$BuildTask -or '.' -eq $BuildTask) {
		$BuildTask = if ($all['.']) {'.'} else {$all.Item(0).Name}
	}
}

### get script parameter help
$Help = @(&{
	Set-StrictMode -Off
	if ($r = Get-Help $BuildFile) {if ($r = $r.parameters) {if ($r = $r.parameter) {$r}}}
})

### get script parameters
$CommonParameters = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'ErrorVariable', 'WarningVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'InformationAction', 'InformationVariable'
$Parameters = (Get-Command $BuildFile).Parameters
foreach($name in @($Parameters.Keys)) {
	if ($CommonParameters -contains $name) {
		$null = $Parameters.Remove($name)
	}
}

# amend options
$NoCode = $NoCode -or $PSVersionTable.PSVersion.Major -le 2

# globals
$Hash = @{}
$BuildJobs = @()
$MapParameter = @{}
$MapEnvironment = @{}
$VariableExpressionAst = {$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]}

# collect jobs to do in $BuildJobs
function Add-TaskJob($Jobs, $Task) {
	foreach($job in $Jobs) {
		$job, $null = *Job $job
		if ($job -is [string]) {
			$task2 = $all[$job]
			Add-TaskJob $task2.Jobs $task2
		}
		else {
			if ($BuildJobs -notcontains $Task.Name) {
				$script:BuildJobs += $Task.Name
			}
		}
	}

	if ($Task -and $Task.If -is [scriptblock]) {
		if ($BuildJobs -notcontains $Task.Name) {
			$script:BuildJobs += $Task.Name
		}
	}
}

# get parameters and environment from comments
function Get-TaskComment($Task) {
	$f = ($I = $Task.InvocationInfo).ScriptName
	if (!($d = $Hash[$f])) {
		$Hash[$f] = $d = @{T = Get-Content -LiteralPath $f; C = @{}}
		foreach($_ in [System.Management.Automation.PSParser]::Tokenize($d.T, [ref]$null)) {
			if ($_.Type -eq 15) {$d.C[$_.EndLine] = $_.Content}
		}
	}
	$r = @{Parameters = @(); Environment = @()}
	for($n = $I.ScriptLineNumber; --$n -ge 1) {
		if ($c = $d.C[$n]) {
			if ($c -match '(?m)^\s*#*\s*Parameters\s*:(.*)') {$r.Parameters = $Matches[1].Trim() -split '[\s,]+'}
			elseif ($c -match '(?m)^\s*#*\s*Environment\s*:(.*)') {$r.Environment = $Matches[1].Trim() -split '[\s,]+'}
		}
		elseif ($d.T[$n - 1].Trim()) {
			break
		}
	}
	$r
}

function Add-VariablePath($Path) {
	$index = $Path.IndexOf(':')
	if ($index -ge 0) {
		$prefix = $Path.Substring(0, $index)
		$name = $Path.Substring($index + 1)
	}
	else {
		$prefix = ''
		$name = $Path
	}
	if (!$prefix -or $prefix -eq 'script') {
		if ($Parameters.ContainsKey($name)) {
			$MapParameter[$name] = 1
		}
	}
	elseif ($prefix -eq 'env') {
		$MapEnvironment[$name] = 1
	}
}

function Add-BlockVariable($Block) {
	$variables = $job.Ast.FindAll($VariableExpressionAst, $true)
	foreach($variable in $variables) {
		$parent = $variable.Parent
		if ($parent -isnot [System.Management.Automation.Language.AssignmentStatementAst] -or $parent.Left -ne $variable) {
			Add-VariablePath $variable.VariablePath.UserPath
		}
	}
}

function Add-TaskVariable($Jobs) {
	foreach($job in $Jobs) {
		$task = $all[$job]
		$info = Get-TaskComment $task

		foreach($name in $info.Environment) {
			$MapEnvironment[$name] = 1
		}
		foreach($name in $info.Parameters) {
			if ($Parameters.ContainsKey($name)) {
				$MapParameter[$name] = 1
			}
			else {
				Write-Warning "Task '$($task.Name)': unknown parameter '$name'."
			}
		}

		if (!$NoCode) {
			$job = $Task.If
			if ($job -is [scriptblock]) {
				Add-BlockVariable $job
			}
			foreach($job in $task.Jobs) {
				if ($job -is [scriptblock]) {
					Add-BlockVariable $job
				}
			}
		}
	}
}

function Format-TaskHelp($TaskHelp) {
	Write-Build White Task:
	foreach($r in $TaskHelp.Task) {
		if ($r.Synopsis) {
			Write-Build Gray ('    {0} - {1}' -f $r.Name, $r.Synopsis)
		}
		else {
			Write-Build Gray ('    {0}' -f $r.Name)
		}
	}

	Write-Build White Jobs:
	foreach($r in $TaskHelp.Jobs) {
		Write-Build Gray ('    {0} - {1}' -f $r.Name, $r.Location)
	}

	if ($TaskHelp.Parameters) {
		Write-Build White Parameters:
		foreach($param in $TaskHelp.Parameters) {
			Write-Build Gray ('    [{0}] {1}' -f $param.Type, $param.Name)
			if ($param.Description) {
				Write-Build Gray ('        {0}' -f $param.Description)
			}
		}
	}

	if ($TaskHelp.Environment) {
		Write-Build White Environment:
		Write-Build Gray ('    {0}' -f ($TaskHelp.Environment -join ', '))
	}
}

### .Task
$TaskHelp = 1 | Select-Object Task, Jobs, Synopsis, Location, Parameters, Environment
$TaskHelp.Task = @(
	foreach($job in $BuildTask) {
		$job, $null = *Job $job
		$task = $all[$job]
		if (!$task) {*Fin "Missing task '$job' in '$BuildFile'." 5}
		$r = 1 | Select-Object Name, Synopsis
		$r.Name = $task.Name
		$r.Synopsis = Get-BuildSynopsis $task $Hash
		$r
	}
)

### .Jobs
Add-TaskJob $BuildTask
$TaskHelp.Jobs = @(
	foreach($name in $BuildJobs) {
		$task = $all[$name]
		$r = 1 | Select-Object Name, Location
		$r.Name = $task.Name
		$r.Location = '{0}:{1}' -f $task.InvocationInfo.ScriptName, $task.InvocationInfo.ScriptLineNumber
		$r
	}
)

### .Parameters and .Environment
Add-TaskVariable $BuildJobs
$TaskHelp.Environment = @($MapEnvironment.Keys | Sort-Object)

# make parameter objects with help
$TaskHelp.Parameters = @()
foreach($name in $MapParameter.Keys) {
	$param = $Parameters[$name]
	$r = 1 | Select-Object Name, Type, Description
	$r.Name = $name

	$type = $param.ParameterType.Name
	if ($type -eq 'SwitchParameter') {
		$r.Type = 'switch'
	}
	else {
		$r.Type = $type
	}

	$r.Description = foreach($_ in $Help) {
		if ($_.name -eq $name -and $_.PSObject.Properties['description']) {
			($_.description | Out-String).Trim()
			break
		}
	}
	$TaskHelp.Parameters += $r
}
$TaskHelp.Parameters = @($TaskHelp.Parameters | Sort-Object {$_.Type -eq 'switch'}, Name)

# finish
& $Format $TaskHelp
