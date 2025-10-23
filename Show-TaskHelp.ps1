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

.Parameter Format
		Specifies the custom task help formatter.

.Link
	https://github.com/nightroman/Invoke-Build
#>

param(
	[Parameter(Position=0)]
	[string[]]$Task
	,
	[Parameter(Position=1)]
	[string]$File
	,
	[object]$Format = $(if ($Format = $PSCmdlet.GetVariableValue('Format')) {$Format} else {'Format-TaskHelp'})
	,
	[switch]$NoCode = $PSCmdlet.GetVariableValue('NoCode')
)

$ErrorActionPreference=1; trap {$PSCmdlet.ThrowTerminatingError($_)}

# recall by IB
if ([System.IO.Path]::GetFileName($MyInvocation.ScriptName) -ne 'Invoke-Build.ps1') {
	Invoke-Build $Task $File -WhatIf
	return
}

$All = ${*}.All
$BB = ${*}.BB
$DP = ${*}.DP
Remove-Variable Task

### script parameters help

function get_help($File) {
	Set-StrictMode -Off
	@(if ($r = Get-Help $File) {if ($r = $r.parameters) {if ($r = $r.parameter) {$r}}})
}

$Help = @(
	foreach($b in $BB) {
		get_help $b.FS
	}
)

$Hash = @{}
$BuildJobs = @()
$MapParameter = @{}
$MapEnvironment = @{}

# collect jobs in $BuildJobs
function Add-TaskJob($Jobs, $Task) {
	foreach($job in $Jobs) {
		if ($job -is [string]) {
			$task2 = $All[$job.TrimStart('?')]
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
		if ($DP.ContainsKey($name)) {
			$MapParameter[$name] = 1
		}
	}
	elseif ($prefix -eq 'env') {
		$MapEnvironment[$name] = 1
	}
}

function Add-BlockVariable($Block) {
	foreach($variable in $Block.Ast.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]}, $true)) {
		if ($variable.Parent -isnot [System.Management.Automation.Language.AssignmentStatementAst]) {
			Add-VariablePath $variable.VariablePath.UserPath
		}
	}
}

function Add-TaskVariable($Jobs) {
	foreach($job in $Jobs) {
		$task = $All[$job]
		$info = Get-TaskComment $task

		foreach($name in $info.Environment) {
			$MapEnvironment[$name] = 1
		}
		foreach($name in $info.Parameters) {
			if ($DP.ContainsKey($name)) {
				$MapParameter[$name] = 1
			}
			else {
				Write-Warning "Task '$($task.Name)': unknown parameter '$name'."
			}
		}

		if (!$NoCode) {
			foreach($job in @($Task.If; $Task.Inputs; $Task.Outputs; $task.Jobs)) {
				if ($job -is [scriptblock]) {
					Add-BlockVariable $job
				}
			}
		}
	}
}

function Format-TaskHelp($TaskHelp) {
	print White Task:
	foreach($r in $TaskHelp.Task) {
		if ($synopsis = $r.Synopsis) {
			print Gray ('    {0} - {1}' -f $r.Name, $synopsis)
		}
		else {
			print Gray ('    {0}' -f $r.Name)
		}
	}

	print White Jobs:
	foreach($r in $TaskHelp.Jobs) {
		if ($synopsis = Get-BuildSynopsis ($All[$r.Name]) $Hash) {
			print Gray ('    {0} - {1} At {2}' -f $r.Name, $synopsis, $r.Location)
		}
		else {
			print Gray ('    {0} - At {1}' -f $r.Name, $r.Location)
		}
	}

	if ($TaskHelp.Parameters) {
		print White Parameters:
		foreach($p in $TaskHelp.Parameters) {
			print Gray ('    [{0}] {1}' -f $p.Type, $p.Name)
			if ($p.Description) {
				print Gray ('        {0}' -f $p.Description)
			}
		}
	}

	if ($TaskHelp.Environment) {
		print White Environment:
		print Gray ('    {0}' -f ($TaskHelp.Environment -join ', '))
	}
}

### .Task
$TaskHelp = [pscustomobject]@{Task=$null; Jobs=$null; Synopsis=$null; Location=$null; Parameters=$null; Environment=$null}
$TaskHelp.Task = @(
	foreach($job in $BuildTask) {
		$task = $All[$job.TrimStart('?')]
		[pscustomobject]@{
			Name = $task.Name
			Synopsis = Get-BuildSynopsis $task $Hash
		}
	}
)

### .Jobs
Add-TaskJob $BuildTask
$TaskHelp.Jobs = @(
	foreach($name in $BuildJobs) {
		$task = $All[$name]
		[pscustomobject]@{
			Name = $task.Name
			Location = '{0}:{1}' -f $task.InvocationInfo.ScriptName, $task.InvocationInfo.ScriptLineNumber
		}
	}
)

### .Parameters and .Environment
Add-TaskVariable $BuildJobs
$TaskHelp.Environment = @($MapEnvironment.get_Keys() | Sort-Object)

# make parameter objects with help
$TaskHelp.Parameters = @()
foreach($name in $MapParameter.get_Keys()) {
	$p = $DP[$name]
	$r = [pscustomobject]@{
		Name = $name
		Type = $(if (($type = $p.ParameterType.Name) -eq 'SwitchParameter') {'switch'} else {$type})
		Description = foreach($_ in $Help) {
			if ($_.name -eq $name -and $_.PSObject.Properties['description']) {
				($_.description | Out-String).Trim()
				break
			}
		}
	}
	$TaskHelp.Parameters += $r
}
$TaskHelp.Parameters = @($TaskHelp.Parameters | Sort-Object {$_.Type -eq 'switch'}, Name)

### format
& $Format $TaskHelp
