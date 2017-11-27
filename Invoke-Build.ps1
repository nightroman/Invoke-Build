
<#
Copyright 2011-2017 Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
#>

#.ExternalHelp InvokeBuild-Help.xml
param(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)]$File,
	$Result,
	[switch]$Safe,
	[switch]$Summary,
	[switch]$WhatIf
)

dynamicparam {

function *Path($P) {
	$PSCmdlet.GetUnresolvedProviderPathFromPSPath($P)
}

function *Die($M, $C=0) {
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, $C, $null))
}

function Get-BuildFile($Path) {
	do {
		if (($f = [System.IO.Directory]::GetFiles($Path, '*.build.ps1')).Length -eq 1) {return $f}
		if ($_ = $f -match '[\\/]\.build\.ps1$') {return $_}
		if ($f.Length -ge 2) {throw "Ambiguous default script in '$Path'."}
		if ([System.IO.File]::Exists(($_ = $env:InvokeBuildGetFile)) -and ($_ = & $_ $Path)) {return $_}
	} while($Path = Split-Path $Path)
}

if ($MyInvocation.InvocationName -eq '.') {return}
trap {*Die $_ 13}

New-Variable * -Description IB ([PSCustomObject]@{
	All = [System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase)
	Tasks = [System.Collections.Generic.List[object]]@()
	Errors = [System.Collections.Generic.List[object]]@()
	Warnings = [System.Collections.Generic.List[object]]@()
	Redefined = @()
	Doubles = @()
	Started = [DateTime]::Now
	Elapsed = $null
	Error = $null
	Task = $null
	File = $BuildFile = $PSBoundParameters['File']
	Safe = $PSBoundParameters['Safe']
	Summary = $PSBoundParameters['Summary']
	CD = *Path
	DP = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	SP = @{}
	P = $(if ($_ = $PSCmdlet.SessionState.PSVariable.Get('*')) {if ($_.Description -eq 'IB') {$_.Value}})
	A = 1
	B = 0
	Q = 0
	H = @{}
	EnterBuild = $null
	ExitBuild = $null
	EnterTask = $null
	ExitTask = $null
	EnterJob = $null
	ExitJob = $null
	Header = {Write-Build 11 "Task $($args[0])"}
	Data = @{}
	XBuild = $null
	XTask = $null
})
$BuildTask = $PSBoundParameters['Task']
if ($BuildFile -is [scriptblock]) {
	$BuildFile = $BuildFile.File
	return
}

if ($BuildTask -eq '**') {
	if (![System.IO.Directory]::Exists(($_ = *Path $BuildFile))) {throw "Missing directory '$_'."}
	$BuildFile = @(Get-ChildItem -LiteralPath $_ -Filter *.test.ps1 -Recurse)
	return
}

if ($BuildFile) {
	if (![System.IO.File]::Exists(($BuildFile = *Path $BuildFile))) {throw "Missing script '$BuildFile'."}
}
elseif (!($BuildFile = Get-BuildFile ${*}.CD)) {
	throw 'Missing default script.'
}
${*}.File = $BuildFile

if (!($_ = (Get-Command $BuildFile -ErrorAction 1).Parameters)) {
	& $BuildFile
	throw 'Invalid script.'
}
if ($_.Count) {&{
	($a = New-Object System.Collections.ObjectModel.Collection[Attribute]).Add((New-Object System.Management.Automation.ParameterAttribute))
	$c = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'ErrorVariable', 'WarningVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'InformationAction', 'InformationVariable'
	$r = 'Task', 'File', 'Result', 'Safe', 'Summary', 'WhatIf'
	foreach($p in $_.Values) {
		if ($c -notcontains ($_ = $p.Name)) {
			if ($r -contains $_) {throw "Script uses reserved parameter '$_'."}
			${*}.DP.Add($_, (New-Object System.Management.Automation.RuntimeDefinedParameter $_, $p.ParameterType, $a))
		}
	}
	${*}.DP
}}

} end {

#.ExternalHelp InvokeBuild-Help.xml
function Add-BuildTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	[object[]]$After,
	[object[]]$Before,
	$If=$true,
	$Inputs,
	$Outputs,
	$Data,
	$Done,
	$Source=$MyInvocation,
	[switch]$Partial
)
{
	trap {*Die "Task '$Name': $_" 5}
	if ($Name[0] -eq '?') {throw 'Invalid task name.'}
	if ($_ = ${*}.All[$Name]) {${*}.Redefined += $_}
	${*}.All[$Name] = [PSCustomObject]@{
		Name = $Name
		Error = $null
		Started = $null
		Elapsed = $null
		Jobs = $1 = [System.Collections.Generic.List[object]]@()
		After = $After
		Before = $Before
		If = $If
		Inputs = $Inputs
		Outputs = $Outputs
		Data = $Data
		Done = $Done
		Partial = $Partial
		InvocationInfo = $Source
	}
	if (!$Jobs) {return}
	$1.AddRange($Jobs)
	$2 = @()
	foreach($j in $1) {
		$r, $null = *Job $j
		if ($2 -contains $r) {${*}.Doubles += ,($Name, $r)}
		$2 += $r
	}
}

#.ExternalHelp InvokeBuild-Help.xml
function Assert-Build([Parameter()]$Condition, [string]$Message) {
	if (!$Condition) {
		*Die "Assertion failed.$(if ($Message) {" $Message"})" 7
	}
}

#.ExternalHelp InvokeBuild-Help.xml
function Assert-BuildEquals([Parameter()]$A, $B) {
	if (![Object]::Equals($A, $B)) {
		*Die @"
Objects are not equal:
A:$(if ($null -ne $A) {" $A [$($A.GetType())]"})
B:$(if ($null -ne $B) {" $B [$($B.GetType())]"})
"@ 7
	}
}

#.ExternalHelp InvokeBuild-Help.xml
function Get-BuildError([Parameter(Mandatory=1)][string]$Task) {
	if (!($_ = ${*}.All[$Task])) {
		*Die "Missing task '$Task'." 13
	}
	$_.Error
}

#.ExternalHelp InvokeBuild-Help.xml
function Get-BuildProperty([Parameter(Mandatory=1)][string]$Name, $Value) {
	${*n} = $Name
	${*v} = $Value
	Remove-Variable Name, Value
	if (($null -ne ($_ = $PSCmdlet.GetVariableValue(${*n})) -and '' -ne $_) -or ($_ = [Environment]::GetEnvironmentVariable(${*n}))) {return $_}
	if ($null -eq ${*v}) {*Die "Missing property '${*n}'." 13}
	${*v}
}

#.ExternalHelp InvokeBuild-Help.xml
function Get-BuildSynopsis([Parameter(Mandatory=1)]$Task, $Hash=${*}.H) {
	$f = ($I = $Task.InvocationInfo).ScriptName
	if (!($d = $Hash[$f])) {
		$Hash[$f] = $d = @{}
		foreach($_ in [System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $f), [ref]$null)) {
			if ($_.Type -eq 'Comment') {$d[$_.EndLine] = $_.Content}
		}
	}
	for($n = $I.ScriptLineNumber; --$n -ge 1 -and ($c = $d[$n])) {
		if ($c -match '(?m)^\s*#*\s*Synopsis\s*:\s*(.*)$') {return $Matches[1]}
	}
}

#.ExternalHelp InvokeBuild-Help.xml
function Invoke-BuildExec([Parameter(Mandatory=1)][scriptblock]$Command, [int[]]$ExitCode=0) {
	${private:*c} = $Command
	${private:*x} = $ExitCode
	Remove-Variable Command, ExitCode
	& ${*c}
	if (${*x} -notcontains $global:LastExitCode) {
		*Die "Command {${*c}} exited with code $global:LastExitCode." 8
	}
}

#.ExternalHelp InvokeBuild-Help.xml
function Test-BuildAsset([Parameter(Position=0)][string[]]$Variable, [string[]]$Environment, [string[]]$Property) {
	Remove-Variable Variable, Environment, Property
	if ($_ = $PSBoundParameters['Variable']) {foreach($_ in $_) {
		if ($null -eq ($$ = $PSCmdlet.GetVariableValue($_)) -or '' -eq $$) {*Die "Missing variable '$_'." 13}
	}}
	if ($_ = $PSBoundParameters['Environment']) {foreach($_ in $_) {
		if (!([Environment]::GetEnvironmentVariable($_))) {*Die "Missing environment variable '$_'." 13}
	}}
	if ($_ = $PSBoundParameters['Property']) {foreach($_ in $_) {
		if ('' -eq (Get-BuildProperty $_ '')) {*Die "Missing property '$_'." 13}
	}}
}

#.ExternalHelp InvokeBuild-Help.xml
function Use-BuildAlias([Parameter(Mandatory=1)][string]$Path, [string[]]$Name) {
	trap {*Die $_ 5}
	$d = switch -regex ($Path) {
		'^\*|^\d+\.' {Split-Path (Resolve-MSBuild $_)}
		^Framework {"$env:windir\Microsoft.NET\$_"}
		^VisualStudio\\ {
			$x = if ([IntPtr]::Size -eq 8) {'\Wow6432Node'}
			[Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SOFTWARE$x\Microsoft\$_", 'InstallDir', '')
		}
		default {*Path $_}
	}
	if (![System.IO.Directory]::Exists($d)) {throw "Cannot resolve '$Path'."}
	foreach($_ in $Name) {
		Set-Alias $_ (Join-Path $d $_) -Scope 1
	}
}

#.ExternalHelp InvokeBuild-Help.xml
function Write-Build([ConsoleColor]$Color, [string]$Text) {
	$i = $Host.UI.RawUI
	$_ = $i.ForegroundColor
	try {
		$i.ForegroundColor = $Color
		$Text
	}
	finally {
		$i.ForegroundColor = $_
	}
}
if ($env:APPVEYOR) {
	function Write-Build([ConsoleColor]$Color, [string]$Text) {Write-Host $Text -ForegroundColor $Color}
}
else {
	try {$null = Write-Build 0} catch {function Write-Build($Color, [string]$Text) {$Text}}
}

function *My {
	$_.InvocationInfo.ScriptName -eq $MyInvocation.ScriptName
}

function *SL($P=$BuildRoot) {
	Set-Location -LiteralPath $P -ErrorAction 1
}

function *Run($_) {
	if ($_ -and !$WhatIf) {
		*SL
		. $_ @args
	}
}

function *At($I) {
	$I.InvocationInfo.PositionMessage.Trim()
}

function *Error($M, $I) {
@"
$M
$(*At $I)
"@
}

function *Job($J) {
	if ($J -is [string]) {if ($J[0] -eq '?') {$J.Substring(1), 1} else {$J}}
	elseif ($J -is [scriptblock]) {$J}
	else {throw 'Invalid job.'}
}

function *Unsafe($N, $J) {
	if ($J -contains $N) {return 1}
	foreach($_ in $J) {
		$r, $null = *Job $_
		if ($r -ne $N -and ($t = ${*}.All[$r]) -and $t.If -and (*Unsafe $N $t.Jobs)) {
			return 1
		}
	}
}

function *Amend([Parameter()]$X, $J, $B) {
	trap {*Die (*Error "Task '$n': $_" $X) 5}
	$n = $X.Name
	foreach($_ in $J) {
		$r, $s = *Job $_
		if (!($t = ${*}.All[$r])) {throw "Missing task '$r'."}
		$j = $t.Jobs
		$i = $j.Count
		if ($B) {
			for($k = -1; ++$k -lt $i -and $j[$k] -is [string]) {}
			$i = $k
		}
		$j.Insert($i, $(if ($s) {"?$n"} else {$n}))
	}
}

function *Check([Parameter()]$J, $T, $P=@()) {
	foreach($_ in $J) { if ($_ -is [string]) {
		$_, $null = *Job $_
		if (!($r = ${*}.All[$_])) {
			$_ = "Missing task '$_'."
			*Die $(if ($T) {*Error "Task '$($T.Name)': $_" $T} else {$_}) 5
		}
		if ($P -contains $r) {
			*Die (*Error "Task '$($T.Name)': Cyclic reference to '$_'." $T) 5
		}
		*Check $r.Jobs $r ($P + $r)
	}}
}

function *AddError($T) {
	${*}.Errors.Add([PSCustomObject]@{Error = $_; File = $BuildFile; Task = $T})
	Write-Build 12 "ERROR: $(if (*My) {$_} else {*Error $_ $_})"
}

filter *Help {
	$r = 1 | Select-Object Name, Jobs, Synopsis
	$r.Name = $_.Name
	$r.Jobs = foreach($j in $_.Jobs) {if ($j -is [string]) {$j} else {'{}'}}
	$r.Synopsis = Get-BuildSynopsis $_
	$r
}

function *Root($A) {
	*Check $A.Keys
	$h = @{}
	foreach($_ in $A.Values) {foreach($_ in $_.Jobs) {
		if ($_ -is [string]) {
			$_, $null = *Job $_
			$h[$_] = 1
		}
	}}
	foreach($_ in $A.Keys) {if (!$h[$_]) {$_}}
}

function *IO {
	if ((${private:*i} = $Task.Inputs) -is [scriptblock]) {
		*SL
		${*i} = @(& ${*i})
	}
	*SL
	${private:*p} = [System.Collections.Generic.List[object]]@()
	${*i} = foreach($_ in ${*i}) {
		if ($_ -isnot [System.IO.FileInfo]) {$_ = [System.IO.FileInfo](*Path $_)}
		if (!$_.Exists) {throw "Missing Inputs item '$_'."}
		$_
		${*p}.Add($_.FullName)
	}
	if (!${*p}) {return 2, 'Skipping empty input.'}

	${private:*o} = $Task.Outputs
	if ($Task.Partial) {
		${*o} = @(
			if (${*o} -is [scriptblock]) {
				${*p} | & ${*o}
				*SL
			}
			else {
				${*o}
			}
		)
		if (${*p}.Count -ne ${*o}.Count) {throw "Different Inputs/Outputs counts: $(${*p}.Count)/$(${*o}.Count)."}

		$k = -1
		$Task.Inputs = $i = [System.Collections.Generic.List[object]]@()
		$Task.Outputs = $o = [System.Collections.Generic.List[object]]@()
		foreach($_ in ${*i}) {
			$f = *Path ($p = ${*o}[++$k])
			if (![System.IO.File]::Exists($f) -or $_.LastWriteTime -gt [System.IO.File]::GetLastWriteTime($f)) {
				$i.Add(${*p}[$k])
				$o.Add($p)
			}
		}
		if ($i) {return $null, "Out-of-date outputs: $($o.Count)/$(${*p}.Count)."}
	}
	else {
		if (${*o} -is [scriptblock]) {
			$Task.Outputs = ${*o} = ${*p} | & ${*o}
			*SL
		}
		if (!${*o}) {throw 'Outputs must not be empty.'}

		$Task.Inputs = ${*p}
		$m = (${*i} | .{process{$_.LastWriteTime.Ticks}} | Measure-Object -Maximum).Maximum
		foreach($_ in ${*o}) {
			$p = *Path $_
			if (![System.IO.File]::Exists($p) -or $m -gt [System.IO.File]::GetLastWriteTime($p).Ticks) {
				return $null, "Out-of-date output '$_'."
			}
		}
	}
	2, 'Skipping up-to-date output.'
}

function *Task {
	${private:*p} = "$($args[1])/$($args[0])"
	${private:*n}, ${private:*s} = *Job $args[0]
	New-Variable Task (${*}.Task = ${*}.All[${*n}]) -Option Constant

	if ($Task.Elapsed) {
		Write-Build 8 "Done ${*p}"
		return
	}

	$Task.Started = [DateTime]::Now
	if (${*}.XTask) {& ${*}.XTask}
	if ((${private:*x} = $Task.If) -is [scriptblock] -and !$WhatIf) {
		*SL
		try {
			${*x} = & ${*x}
		}
		catch {
			*AddError $Task
			${*}.Tasks.Add($Task)
			Write-Build 14 (*At $Task)
			$Task.Elapsed = [TimeSpan]::Zero
			$Task.Error = $_
			throw
		}
	}
	if (!${*x}) {
		Write-Build 8 "Task ${*p} skipped."
		return
	}

	${private:*i} = , [int]($null -ne $Task.Inputs)
	try {
		. *Run ${*}.EnterTask
		foreach(${private:*j} in $Task.Jobs) {
			if (${*j} -is [string]) {
				*Task ${*j} ${*p}
				continue
			}

			& ${*}.Header ${*p}
			if ($WhatIf) {
				${*j}
				continue
			}

			if (1 -eq ${*i}[0]) {
				try {
					${*i} = *IO
				}
				catch {
					*AddError $Task
					throw
				}
				Write-Build 8 ${*i}[1]
			}
			if (${*i}[0]) {
				continue
			}

			try {
				. *Run ${*}.EnterJob
				*SL
				if (0 -eq ${*i}[0]) {
					& ${*j}
				}
				else {
					$Inputs = $Task.Inputs
					$Outputs = $Task.Outputs
					if ($Task.Partial) {
						${*x} = 0
						$Inputs | .{process{
							$2 = $Outputs[${*x}++]
							$_
						}} | & ${*j}
					}
					else {
						$Inputs | & ${*j}
					}
				}
			}
			catch {
				*AddError $Task
				$Task.Error = $_
				throw
			}
			finally {
				. *Run ${*}.ExitJob
			}
		}
		$Task.Elapsed = [DateTime]::Now - $Task.Started
		if ($_ = $Task.Error) {
			*AddError $Task
			Write-Build 14 (*At $Task)
		}
		else {
			Write-Build 11 "Done ${*p} $($Task.Elapsed)"
		}
		*Run $Task.Done
	}
	catch {
		$Task.Elapsed = [DateTime]::Now - $Task.Started
		$Task.Error = $_
		Write-Build 14 (*At $Task)
		if (!${*s} -or (*Unsafe ${*n} $BuildTask)) {throw}
	}
	finally {
		${*}.Tasks.Add($Task)
		. *Run ${*}.ExitTask
	}
}

function job($Name, [switch]$Safe) {if ($Safe) {"?$Name"} else {$Name}}
Set-Alias assert Assert-Build
Set-Alias equals Assert-BuildEquals
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias property Get-BuildProperty
Set-Alias requires Test-BuildAsset
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias
Set-Alias Invoke-Build ($_ = $MyInvocation.MyCommand.Path)
$_ = Split-Path $_
Set-Alias Build-Parallel (Join-Path $_ Build-Parallel.ps1)
Set-Alias Resolve-MSBuild (Join-Path $_ Resolve-MSBuild.ps1)

if ($MyInvocation.InvocationName -eq '.') {
	if ($_ = $MyInvocation.ScriptName) {
		$ErrorActionPreference = 'Stop'
		$BuildFile = $_
		*SL ($BuildRoot = if ($Task) {*Path $Task} else {Split-Path $_})
	}
	Remove-Variable Task, File, Result, Safe, Summary, WhatIf
	return
}

function Write-Warning([Parameter()]$Message) {
	$PSCmdlet.WriteWarning($Message)
	${*}.Warnings.Add([PSCustomObject]@{Message = $Message; File = $BuildFile; Task = ${*}.Task})
}

$ErrorActionPreference = 'Stop'
foreach($_ in $PSBoundParameters.Keys) {
	if (${*}.DP.ContainsKey($_)) {
		${*}.SP[$_] = $PSBoundParameters[$_]
	}
}
if (${*}.Q = $BuildTask -eq '??' -or $BuildTask -eq '?') {
	$WhatIf = $true
}
if ($Result) {
	if ($Result -is [string]) {
		New-Variable $Result ${*} -Scope 1 -Force
	}
	else {
		${*}.XBuild = $Result['XBuild']
		${*}.XTask = $Result['XTask']
		$Result.Value = ${*}
	}
}
Remove-Variable Task, File, Result, Safe, Summary

try {
	if ($BuildTask -eq '**') {
		${*}.A = 0
		foreach($_ in $BuildFile) {
			Invoke-Build @('*'; $BuildTask -ne '**') $_.FullName -Safe:${*}.Safe
		}
		${*}.B = 1
		return
	}

	function Enter-Build([Parameter()][scriptblock]$Script) {${*}.EnterBuild = $Script}
	function Exit-Build([Parameter()][scriptblock]$Script) {${*}.ExitBuild = $Script}
	function Enter-BuildTask([Parameter()][scriptblock]$Script) {${*}.EnterTask = $Script}
	function Exit-BuildTask([Parameter()][scriptblock]$Script) {${*}.ExitTask = $Script}
	function Enter-BuildJob([Parameter()][scriptblock]$Script) {${*}.EnterJob = $Script}
	function Exit-BuildJob([Parameter()][scriptblock]$Script) {${*}.ExitJob = $Script}
	function Set-BuildHeader([Parameter()][scriptblock]$Script) {${*}.Header = $Script}
	function Set-BuildData([Parameter()]$Key, $Value) {${*}.Data[$Key] = $Value}

	*SL ($BuildRoot = if ($BuildFile) {Split-Path $BuildFile} else {${*}.CD})
	$_ = ${*}.SP
	${private:**} = @(. ${*}.File @_)
	foreach($_ in ${**}) {
		Write-Warning "Unexpected output: $_."
		if ($_ -is [scriptblock]) {throw "Dangling scriptblock at $($_.File):$($_.StartPosition.StartLine)"}
	}
	if (!(${**} = ${*}.All).Count) {throw "No tasks in '$BuildFile'."}

	foreach($_ in ${**}.Values) {
		if ($_.Before) {*Amend $_ $_.Before 1}
	}
	foreach($_ in ${**}.Values) {
		if ($_.After) {*Amend $_ $_.After}
	}

	if (${*}.Q) {
		*Check ${**}.Keys
		if ($BuildTask -eq '??') {
			${**}
		}
		else {
			${**}.Values | *Help
		}
		return
	}

	if ($BuildTask -eq '*') {
		$BuildTask = *Root ${**}
	}
	else {
		if (!$BuildTask -or '.' -eq $BuildTask) {
			$BuildTask = if (${**}['.']) {'.'} else {${**}.Item(0).Name}
		}
		*Check $BuildTask
	}

	New-Variable BuildRoot (*Path $BuildRoot) -Option Constant -Force
	if (![System.IO.Directory]::Exists($BuildRoot)) {throw "Missing build root '$BuildRoot'."}

	Write-Build 11 "Build $($BuildTask -join ', ') $BuildFile"
	foreach($_ in ${*}.Redefined) {
		Write-Build 8 "Redefined task '$($_.Name)'."
	}
	foreach($_ in ${*}.Doubles) {
		if (${*}.All[$_[1]].If -isnot [scriptblock]) {
			Write-Warning "Task '$($_[0])' always skips '$($_[1])'."
		}
	}

	${*}.A = 0
	try {
		. *Run ${*}.EnterBuild
		if (${*}.XBuild) {. ${*}.XBuild}
		foreach($_ in $BuildTask) {
			*Task $_ ''
		}
	}
	finally {
		. *Run ${*}.ExitBuild
	}
	${*}.B = 1
	exit 0
}
catch {
	${*}.B = 2
	${*}.Error = $_
	if (!${*}.Errors) {*AddError}
	if ($_.FullyQualifiedErrorId -eq 'PositionalParameterNotFound,Add-BuildTask') {
		Write-Warning 'Check task positional parameters: a name and comma separated jobs.'
	}
	if (!${*}.Safe) {
		if (*My) {$PSCmdlet.ThrowTerminatingError($_)}
		throw
	}
}
finally {
	*SL ${*}.CD
	if (${*}.B -and !${*}.Q) {
		$t = ${*}.Tasks
		$e = ${*}.Errors
		if (${*}.Summary) {
			Write-Build 11 'Build summary:'
			foreach($_ in $t) {
				'{0,-16} {1} - {2}:{3}' -f $_.Elapsed, $_.Name, $_.InvocationInfo.ScriptName, $_.InvocationInfo.ScriptLineNumber
				if ($_ = $_.Error) {
					Write-Build 12 "ERROR: $(if (*My) {$_} else {*Error $_ $_})"
				}
			}
		}
		if ($w = ${*}.Warnings) {
			foreach($_ in $w) {
				"WARNING: $($_.Message)$(if ($_.Task) {" Task: $($_.Task.Name)."}) File: $($_.File)."
			}
		}
		if ($_ = ${*}.P) {
			$_.Tasks.AddRange($t)
			$_.Errors.AddRange($e)
			$_.Warnings.AddRange($w)
		}
		$c, $m = if (${*}.A) {12, "Build ABORTED $BuildFile"}
		elseif (${*}.B -eq 2) {12, 'Build FAILED'}
		elseif ($e) {14, 'Build completed with errors'}
		elseif ($w) {14, 'Build succeeded with warnings'}
		else {10, 'Build succeeded'}
		Write-Build $c "$m. $($t.Count) tasks, $($e.Count) errors, $($w.Count) warnings $((${*}.Elapsed = [DateTime]::Now - ${*}.Started))"
	}
}
}
