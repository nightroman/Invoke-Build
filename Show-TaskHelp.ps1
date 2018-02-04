
<#
.Synopsis
	Shows Invoke-Build task help information.
	Copyright (c) Roman Kuzmin

.Description
	The command shows the specified or default task help information as task
	name, jobs, synopsis, location, parameters, and environment. By default,
	it analyses the code and called tasks in order to extract parameters and
	environment variables in addition to optionally documented in comments.

	Synopsis is defined in task comments as # Synopsis: ...
	Parameters are defined as # Parameters: name1, name2, ...
	Environment variables are defined as # Environment: name1, name2, ...

	Parameters names match build parameters and separated by spaces or commas.
	Parameter descriptions are taken from the build script comment based help.

	Task help members (for custom formatters):

		Task: [string] Task name.
		Jobs: [string[]] Task jobs, may be empty. Actions are represented as {}.
		Synopsis: [string] Task synopsis, may be null.
		Location: [string] Task location as "<file>:<line>".
		Parameters: [object[]] Task parameters, may be empty.
			Name: [string] Parameter name.
			Type: [string] Parameter type.
			Description: [string] Parameter help, may be null or empty.
		Environment: [string[]] Task environment variables, may be empty.

.Parameter Task
		Build task name. The default is the usual default task.
.Parameter File
		Build script path. The default is the usual default script.
.Parameter NoCode
		Tells to skip code analysis for parameters and environment.
		It is used as true for PowerShell v2.
.Parameter NoTree
		Tells to skip recursive processing of the called task trees.
.Parameter Format
		Specifies the custom task help formatter.

.Link
	https://github.com/nightroman/Invoke-Build
#>

param(
	[Parameter(Position=0)][string]$Task,
	[Parameter(Position=1)]$File,
	$Format = 'Format-TaskHelp',
	[switch]$NoCode,
	[switch]$NoTree
)

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 1

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
$Task = $all[$BuildTask]
if (!$Task) {*Fin "Missing task '$BuildTask' in '$BuildFile'." 5}

### get script help
$Help = Get-Help $BuildFile
$Help = if ($Help.PSObject.Properties['Parameters']) {$Help.Parameters.parameter} else {@()}

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

$Hash = @{}
function Get-TaskInfo($Task) {
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

$MapParameter = @{}
$MapEnvironment = @{}

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

$VariableExpressionAst = {$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]}

function Add-BlockParameter($Block) {
	$variables = $job.Ast.FindAll($VariableExpressionAst, $true)
	foreach($variable in $variables) {
		$parent = $variable.Parent
		if ($parent -isnot [System.Management.Automation.Language.AssignmentStatementAst] -or $parent.Left -ne $variable) {
			Add-VariablePath $variable.VariablePath.UserPath
		}
	}
}

function Add-TaskParameter($Task) {
	$info = Get-TaskInfo $Task
	foreach($name in $info.Environment) {
		$MapEnvironment[$name] = 1
	}
	foreach($name in $info.Parameters) {
		if ($Parameters.ContainsKey($name)) {
			$MapParameter[$name] = 1
		}
		else {
			Write-Warning "Task '$($Task.Name)': unknown parameter '$name'."
		}
	}

	if (!$NoCode) {
		$job = $Task.If
		if ($job -is [scriptblock]) {
			Add-BlockParameter $job
		}
	}

	foreach($job in $Task.Jobs) {
		$job, $null = *Job $job
		if ($job -is [string]) {
			if (!$NoTree) {
				$task2 = $all[$job]
				Add-TaskParameter $task2
			}
		}
		elseif (!$NoCode) {
			Add-BlockParameter $job
		}
	}
}

function Format-TaskHelp($TaskHelp) {
	Write-Build White Task:
	Write-Build Gray ('    {0}' -f $TaskHelp.Task)

	Write-Build White Jobs:
	Write-Build Gray ('    {0}' -f ($TaskHelp.Jobs -join ', '))

	if ($TaskHelp.Synopsis) {
		Write-Build White Synopsis:
		Write-Build Gray ('    {0}' -f $TaskHelp.Synopsis)
	}

	Write-Build White Location:
	Write-Build Gray ('    {0}' -f $TaskHelp.Location)

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

### task help
$TaskHelp = 1 | Select-Object Task, Jobs, Synopsis, Location, Parameters, Environment
$TaskHelp.Task = $Task.Name
$TaskHelp.Jobs = @(foreach($job in $Task.Jobs) {if ($job -is [string]) {$job} else {'{}'}})
$TaskHelp.Synopsis = Get-BuildSynopsis $Task $Hash
$TaskHelp.Location = '{0}:{1}' -f $Task.InvocationInfo.ScriptName, $Task.InvocationInfo.ScriptLineNumber

# get parameter and environment names
Add-TaskParameter $Task
$TaskHelp.Environment = @($MapEnvironment.Keys | Sort-Object)

# make parameter objects
$TaskHelp.Parameters = @()
foreach($name in @($MapParameter.Keys | Sort-Object)) {
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

# finish
& $Format $TaskHelp
