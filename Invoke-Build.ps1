
<#
Copyright 2011-2016 Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
#>

#.ExternalHelp Invoke-Build-Help.xml
param(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][hashtable]$Parameters,
	[string]$Checkpoint,
	$Result,
	[switch]$Safe,
	[switch]$Summary,
	[switch]$Resume,
	[switch]$WhatIf
)

dynamicparam {

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildFile($Path) {
	do {
		if (($_ = [System.IO.Directory]::GetFiles($Path, '*.build.ps1')).Length -eq 1 -or ($_ = $_ -like '*\.build.ps1')) {return $_}
		if ([System.IO.File]::Exists(($_ = $env:InvokeBuildGetFile)) -and ($_ = & $_ $Path)) {return $_}
	} while($Path = Split-Path $Path)
}

function *FP($_) {
	$PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)
}

function *TE($M, $C=0) {
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, $C, $null))
}

if ($MyInvocation.InvocationName -eq '.') {return}
trap {*TE $_ 13}

$BuildTask = $PSBoundParameters['Task']
$BuildFile = $PSBoundParameters['File']
${private:*Parameters} = $PSBoundParameters['Parameters']
${private:*Checkpoint} = $PSBoundParameters['Checkpoint']
${private:*Resume} = $PSBoundParameters['Resume']
${private:*cd} = *FP
${private:*cp} = $null
${private:*pn} = 'Task', 'File', 'Parameters', 'Checkpoint', 'Result', 'Safe', 'Summary', 'Resume', 'WhatIf',
'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'ErrorVariable', 'WarningVariable', 'OutVariable', 'OutBuffer',
'PipelineVariable', 'InformationAction', 'InformationVariable'

if ($BuildTask -eq '**') {
	if (![System.IO.Directory]::Exists(($_ = *FP $BuildFile))) {throw "Missing directory '$_'."}
	$BuildFile = @(Get-ChildItem -LiteralPath $_ -Filter *.test.ps1 -Recurse)
	return
}

if (${*Checkpoint}) {${*Checkpoint} = *FP ${*Checkpoint}}
if (${*Resume}) {
	if (!${*Checkpoint}) {throw 'Checkpoint must be defined for Resume.'}
	${*cp} = Import-Clixml ${*Checkpoint}
	$BuildTask = ${*cp}.Task
	$BuildFile = ${*cp}.File
	${*Parameters} = ${*cp}.Prm1
	return
}

if ($BuildFile) {
	if (![System.IO.File]::Exists(($BuildFile = *FP $BuildFile))) {throw "Missing script '$BuildFile'."}
}
elseif (!($BuildFile = Get-BuildFile ${*cd})) {
	throw 'Missing default script.'
}

if (${*Parameters}) {return}

$_ = Get-Command -Name $BuildFile -CommandType ExternalScript -ErrorAction 1
if (!($_ = $_.Parameters) -or !$_.Count) {return}

${private:*r} = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
(${private:*a} = New-Object System.Collections.ObjectModel.Collection[Attribute]).Add((New-Object System.Management.Automation.ParameterAttribute))
foreach($_ in $_.Values) {
	if (${*pn} -notcontains $_.Name) {
		${*r}.Add($_.Name, (New-Object System.Management.Automation.RuntimeDefinedParameter $_.Name, $_.ParameterType, ${*a}))
	}
}
${*r}

} end {

#.ExternalHelp Invoke-Build-Help.xml
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
	${*}.All[$Name] = [PSCustomObject]@{
		Name = $Name
		Error = $null
		Started = $null
		Elapsed = $null
		Jobs = $1 = [IB]::List()
		Safe = $2 = [IB]::List()
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
	trap {*TE "Task '$Name': $_" 5}
	foreach($_ in $Jobs) {
		$r, $d = *RJ $_
		$1.Add($r)
		if (1 -eq $d) {
			$2.Add($r)
		}
	}
}

#.ExternalHelp Invoke-Build-Help.xml
function New-BuildJob([Parameter(Mandatory=1)][string]$Name, [switch]$Safe) {
	if ($Safe) {@{$Name = 1}} else {$Name}
}

#.ExternalHelp Invoke-Build-Help.xml
function Assert-Build([Parameter()]$Condition, [string]$Message) {
	if (!$Condition) {
		*TE "Assertion failed.$(if ($Message) {" $Message"})" 7
	}
}

#.ExternalHelp Invoke-Build-Help.xml
function Assert-BuildEquals([Parameter()]$A, $B) {
	if (![Object]::Equals($A, $B)) {
		*TE @"
Objects are not equal:
A:$(if ($null -ne $A) {" $A [$($A.GetType())]"})
B:$(if ($null -ne $B) {" $B [$($B.GetType())]"})
"@ 7
	}
}

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildError([Parameter(Mandatory=1)][string]$Task) {
	if (!($_ = ${*}.All[$Task])) {
		*TE "Missing task '$Task'." 13
	}
	$_.Error
}

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildProperty([Parameter(Mandatory=1)][string]$Name, $Value) {
	if ($null -eq ($_ = $PSCmdlet.GetVariableValue($Name)) -and $null -eq ($_ = [Environment]::GetEnvironmentVariable($Name)) -and $null -eq ($_ = $Value)) {
		*TE "Missing variable '$Name'." 13
	}
	$_
}

#.ExternalHelp Invoke-Build-Help.xml
function Invoke-BuildExec([Parameter(Mandatory=1)][scriptblock]$Command, [int[]]$ExitCode=0) {
	${private:*c} = $Command
	${private:*x} = $ExitCode
	Remove-Variable Command, ExitCode
	. ${*c}
	if (${*x} -notcontains $LastExitCode) {
		*TE "Command {${*c}} exited with code $LastExitCode." 8
	}
}

#.ExternalHelp Invoke-Build-Help.xml
function Use-BuildAlias([Parameter(Mandatory=1)][string]$Path, [string[]]$Name) {
	trap {*TE $_ 5}
	$d = switch -regex ($Path) {
		'^\*$' {@(Get-ChildItem HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions | Sort-Object {[Version]$_.PSChildName})[-1].GetValue('MSBuildToolsPath')}
		'^\d+\.' {[Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$_", 'MSBuildToolsPath', '')}
		'^Framework' {"$env:windir\Microsoft.NET\$_"}
		default {*FP $_}
	}
	if (![System.IO.Directory]::Exists($d)) {throw "Cannot resolve '$Path'."}
	foreach($_ in $Name) {
		Set-Alias $_ (Join-Path $d $_) -Scope 1
	}
}

Add-Type @'
using System;
using System.Collections.Generic;
using System.Management.Automation.Host;
public class IB {
	[ThreadStatic] static ConsoleColor _c;
	[ThreadStatic] static PSHostRawUserInterface _u;
	static public void Init(PSHost h) {if (h.UI != null) _u = h.UI.RawUI;}
	static public void RC() {if (_u != null) {try {_u.ForegroundColor = _c;} catch {}}}
	static public void SC(ConsoleColor c) {if (_u != null) {try {_c = _u.ForegroundColor; _u.ForegroundColor = c;} catch {_u = null;}}}
	static public object List() {return new List<object>();}
}
'@
[IB]::Init($Host)

#.ExternalHelp Invoke-Build-Help.xml
function Write-Build([ConsoleColor]$Color, [string]$Text) {
	try {
		[IB]::SC($Color)
		$Text
	}
	finally {
		[IB]::RC()
	}
}

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildVersion {[Version]'2.14.6'}

function *My {
	$_.InvocationInfo.ScriptName -like '*\Invoke-Build.ps1'
}

function *SL($_=$BuildRoot) {
	Set-Location -LiteralPath $_ -ErrorAction 1
}

function *UC($_) {
	if (!$WhatIf) {
		*SL
		. $_ @args
	}
}

function *II($_) {
	$_.InvocationInfo.PositionMessage.Trim()
}

function *EI($E, $I) {
	"$E`r`n$(*II $I)"
}

function *RJ($_) {
	if ($_ -is [scriptblock] -or $_ -is [string]) {
		$_
	}
	elseif ($_ -is [hashtable] -and $_.Count -eq 1) {
		$_.Keys
		$_.Values
	}
	else {throw 'Invalid job.'}
}

function *Bad($B, $J, $X) {
	foreach($_ in $J) {
		if (($t = ${*}.All[$_]) -and $t.If -and $(if ($_ -eq $B) {$X -notcontains $_} else {*Bad $B $t.Jobs $t.Safe})) {
			return 1
		}
	}
}

filter *AB($N, $B) {
	$r, $d = *RJ $_
	if (!($t = ${*}.All[$r])) {throw "Missing task '$r'."}
	$j = $t.Jobs
	$i = $j.Count
	if ($B) {
		for($k = -1; ++$k -lt $i -and $j[$k] -is [string]) {}
		$i = $k
	}
	$j.Insert($i, $N)
	if (1 -eq $d) {
		$t.Safe.Add($N)
	}
}

function *Try($J, $T, $P=@()) {
	foreach($_ in $J) { if ($_ -is [string]) {
		if (!($r = ${*}.All[$_])) {
			$_ = "Missing task '$_'."
			throw $(if ($T) {*EI "Task '$($T.Name)': $_" $T} else {$_})
		}
		if ($P -contains $r) {
			throw *EI "Task '$($T.Name)': Cyclic reference to '$_'." $T
		}
		*Try $r.Jobs $r ($P + $r)
	}}
}

function *CP {
	$_ = @{
		User = *UC Export-Build
		Task = $BuildTask
		File = $BuildFile
		Prm1 = ${*}.Parameters
		Prm2 = @{}
		Done = @(foreach($t in ${*}.All.Values) {if ($t.Elapsed) {$t.Name}})
	}
	$p = (Get-Command -Name $BuildFile -CommandType ExternalScript -ErrorAction 1).Parameters
	$n = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'ErrorVariable', 'WarningVariable', 'OutVariable', 'OutBuffer',
	'PipelineVariable', 'InformationAction', 'InformationVariable'
	foreach($k in $p.Keys) {
		if ($n -notcontains $k) {
			$_.Prm2[$k] = Get-Variable -Name $k -Scope Script -ValueOnly
		}
	}
	$_ | Export-Clixml ${*}.Checkpoint
}

function *AE($T) {
	${*}.Errors.Add([PSCustomObject]@{
		Error = $_
		File = $BuildFile
		Task = $T
	})
}

function *TS($I, $H) {
	$f = $I.ScriptName
	if (!($d = $H[$f])) {
		$H[$f] = $d = @{}
		foreach($_ in [System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $f), [ref]$null)) {
			if ($_.Type -eq 'Comment') {$d[$_.EndLine] = $_.Content}
		}
	}
	for($n = $I.ScriptLineNumber; --$n -ge 1 -and ($c = $d[$n])) {
		if ($c -match '(?m)^\s*#*\s*Synopsis\s*:\s*(.*)$') {return $Matches[1]}
	}
}

filter *TH($H) {
	$r = 1 | Select-Object Name, Jobs, Synopsis
	$r.Name = $_.Name
	$r.Jobs = foreach($j in $_.Jobs) {if ($j -is [string]) {$j} else {'{}'}}
	$r.Synopsis = *TS $_.InvocationInfo $H
	$r
}

function *IO {
	if ((${private:*i} = $Task.Inputs) -is [scriptblock]) {
		*SL
		${*i} = @(& ${*i})
	}
	*SL
	${private:*p} = [IB]::List()
	${*i} = foreach($_ in ${*i}) {
		if ($_ -isnot [System.IO.FileInfo]) {$_ = [System.IO.FileInfo](*FP $_)}
		if (!$_.Exists) {throw "Missing Inputs item: '$_'."}
		$_
		${*p}.Add($_.FullName)
	}
	if (!${*p}) {return 'Skipping empty input.'}

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
		$Task.Inputs = $i = [IB]::List()
		$Task.Outputs = $o = [IB]::List()
		foreach($_ in ${*i}) {
			if ($_.LastWriteTime -gt [System.IO.File]::GetLastWriteTime((*FP ($p = ${*o}[++$k])))) {
				$i.Add(${*p}[$k])
				$o.Add($p)
			}
		}
		if ($i) {return}
	}
	else {
		if (${*o} -is [scriptblock]) {
			$Task.Outputs = ${*o} = & ${*o}
			*SL
		}
		if (!${*o}) {throw 'Outputs must not be empty.'}

		$Task.Inputs = ${*p}
		$m = (${*i} | .{process{$_.LastWriteTime.Ticks}} | Measure-Object -Maximum).Maximum
		foreach($_ in ${*o}) {
			if ($m -gt [System.IO.File]::GetLastWriteTime((*FP $_)).Ticks) {return}
		}
	}
	'Skipping up-to-date output.'
}

function *Task {
	New-Variable -Name Task -Value ${*}.All[$args[0]] -Option Constant
	${private:*p} = $args[1] + '/' + $Task.Name
	${*}.Task = $Task

	if ($Task.Elapsed) {
		Write-Build 8 "Done ${*p}"
		return
	}

	if ((${private:*x} = $Task.If) -is [scriptblock] -and !$WhatIf) {
		*SL
		try {
			${*x} = & ${*x}
		}
		catch {
			$Task.Error = $_
			throw
		}
	}
	if (!${*x}) {
		Write-Build 8 "Task ${*p} skipped."
		return
	}

	if (${*}.Checkpoint) {*CP}
	${private:*n} = 0
	${private:*a} = $Task.Jobs
	${private:*i} = [int]($null -ne $Task.Inputs)
	$Task.Started = [DateTime]::Now
	try {
		. *UC Enter-BuildTask
		foreach(${private:*j} in ${*a}) {
			++${*n}
			if (${*j} -is [string]) {
				try {
					*Task ${*j} ${*p}
				}
				catch {
					if (*Bad ${*j} $BuildTask) {throw}
					*AE ${*}.All[${*j}]
					Write-Build 12 (*EI "ERROR: Task ${*p}/${*j}: $_" $_)
				}
				continue
			}

			Write-Build 11 "Task ${*p}"
			if ($WhatIf) {
				${*j}
				continue
			}

			if (1 -eq ${*i}) {${*i} = *IO}
			if (${*i}) {
				Write-Build 8 ${*i}
				continue
			}

			try {
				*SL
				. Enter-BuildJob ${*n}
				*SL
				if (0 -eq ${*i}) {
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
				$Task.Error = $_
				throw
			}
			finally {
				*SL
				. Exit-BuildJob ${*n}
			}
		}
		$Task.Elapsed = [DateTime]::Now - $Task.Started
		if ($_ = $Task.Error) {
			*AE $Task
			Write-Build 14 (*II $Task)
			Write-Build 12 (*EI "ERROR: Task ${*p}: $_" $_)
		}
		else {
			Write-Build 11 "Done ${*p} $($Task.Elapsed)"
		}
		if ($Task.Done) {*UC $Task.Done}
	}
	catch {
		$Task.Elapsed = [DateTime]::Now - $Task.Started
		$Task.Error = $_
		Write-Build 14 (*II $Task)
		throw
	}
	finally {
		${*}.Tasks.Add($Task)
		. *UC Exit-BuildTask
	}
}

Set-Alias assert Assert-Build
Set-Alias equals Assert-BuildEquals
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias job New-BuildJob
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias
Set-Alias Invoke-Build ($_ = $MyInvocation.MyCommand.Path)
Set-Alias Invoke-Builds "$(Split-Path $_)\Invoke-Builds.ps1"

if ($MyInvocation.InvocationName -eq '.') {
	if ($BuildFile = $MyInvocation.ScriptName) {
		$ErrorActionPreference = 'Stop'
		*SL ($BuildRoot = if ($Task) {*FP $Task} else {Split-Path $BuildFile})
	}
	Remove-Variable Task, File, Parameters, Checkpoint, Result, Safe, Summary, Resume, WhatIf
	return
}

function Write-Warning([Parameter()]$Message) {
	$PSCmdlet.WriteWarning($Message)
	${*}.Warnings.Add([PSCustomObject]@{
		Message = $Message
		File = $BuildFile
		Task = ${*}.Task
	})
}

function Enter-Build {} function Enter-BuildTask {} function Enter-BuildJob {}
function Exit-Build {} function Exit-BuildTask {} function Exit-BuildJob {}
function Export-Build {} function Import-Build {}

$ErrorActionPreference = 'Stop'
if (!${*Parameters}) {
	${*Parameters} = @{}
	foreach($_ in $PSBoundParameters.Keys) {
		if (${*pn} -notcontains $_) {
			${*Parameters}[$_] = $PSBoundParameters[$_]
		}
	}
}

if (${private:*0} = $PSCmdlet.SessionState.PSVariable.Get('*')) {
	${*0} = if (${*0}.Description -eq 'IB') {${*0}.Value}
}
New-Variable * -Description IB ([PSCustomObject]@{
	Tasks = [IB]::List()
	Errors = [IB]::List()
	Warnings = [IB]::List()
	All = ${private:*a} = [System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase)
	Parameters = $_ = ${*Parameters}
	Checkpoint = ${*Checkpoint}
	Started = [DateTime]::Now
	Elapsed = $null
	Error = $null
	Task = $null
})
if (${private:*?} = $BuildTask -eq '??' -or $BuildTask -eq '?') {
	$WhatIf = $true
}
if ($Result) {
	if ($Result -is [string]) {
		New-Variable -Force -Scope 1 $Result ${*}
	}
	else {
		$Result.Value = ${*}
	}
}
${private:*Safe} = $Safe
${private:*Summary} = $Summary
Remove-Variable Task, File, Parameters, Checkpoint, Result, Safe, Summary, Resume

${private:*b} = 1
${private:*r} = 0
try {
	if ($BuildTask -eq '**') {
		${*b} = 0
		foreach($_ in $BuildFile) {
			Invoke-Build @('*'; $BuildTask -ne '**') $_.FullName -Safe:${*Safe}
		}
		${*r} = 1
		return
	}

	*SL ($BuildRoot = Split-Path $BuildFile)
	if ($_ = . $BuildFile @_) {
		Write-Warning "$BuildFile output: $_"
	}
	if (!${*a}.Count) {throw "No tasks in '$BuildFile'."}

	try {
		foreach(${private:**} in ${*a}.Values) {
			if (${**}.Before) {${**}.Before | *AB ${**}.Name 1}
		}
		foreach(${**} in ${*a}.Values) {
			if (${**}.After) {${**}.After | *AB ${**}.Name}
		}
	}
	catch {
		throw *EI "Task '$(${**}.Name)': $_" ${**}
	}

	if (${*?}) {
		*Try ${*a}.Keys
		if ($BuildTask -eq '??') {
			${*a}
		}
		else {
			${*a}.Values | *TH @{}
		}
		return
	}

	if ($BuildTask -eq '*') {
		*Try ${*a}.Keys
		${**} = @{}
		foreach($_ in ${*a}.Values) {
			foreach($_ in $_.Jobs) {
				if ($_ -is [string]) {
					${**}[$_] = 1
				}
			}
		}
		$BuildTask = foreach($_ in ${*a}.Keys) {if (!${**}[$_]) {$_}}
	}
	else {
		if (!$BuildTask -or '.' -eq $BuildTask) {
			$BuildTask = if (${*a}['.']) {'.'} else {${*a}.Item(0).Name}
		}
		*Try $BuildTask
	}

	Write-Build 11 "Build $($BuildTask -join ', ') $BuildFile"
	${*b} = 0
	try {
		. *UC Enter-Build
		if (${*cp}) {
			foreach($_ in ${*cp}.Done) {
				${*a}[$_].Elapsed = [TimeSpan]::Zero
			}
			foreach($_ in ${*cp}.Prm2.GetEnumerator()) {
				Set-Variable $_.Key $_.Value
			}
			. *UC Import-Build ${*cp}.User
		}
		foreach($_ in $BuildTask) {
			*Task $_ ''
		}
		if (${*Checkpoint}) {
			[System.IO.File]::Delete(${*Checkpoint})
		}
	}
	finally {
		${*}.Task = $null
		. *UC Exit-Build
	}
	${*r} = 1
}
catch {
	${*r} = 2
	*AE ${*}.Task
	${*}.Error = $_
	if (${*Safe}) {
		Write-Build 12 (*EI "ERROR: $_" $_)
	}
	else {
		if (*My) {$PSCmdlet.ThrowTerminatingError($_)}
		throw
	}
}
finally {
	*SL ${*cd}
	if (${*r} -and !${*?}) {
		$t = ${*}.Tasks
		$e = ${*}.Errors
		if (${*Summary}) {
			Write-Build 11 'Build summary:'
			foreach($_ in $t) {
				'{0,-16} {1} - {2}:{3}' -f $_.Elapsed, $_.Name, $_.InvocationInfo.ScriptName, $_.InvocationInfo.ScriptLineNumber
				if ($_ = $_.Error) {
					Write-Build 12 "ERROR: $(if (*My) {$_} else {*EI $_ $_})"
				}
			}
		}
		if ($w = ${*}.Warnings) {
			foreach($_ in $w) {
				"WARNING: $($_.Message)$(if ($_.Task) {" Task: $($_.Task.Name)."}) File: $($_.File)."
			}
		}
		if (${*0}) {
			${*0}.Tasks.AddRange($t)
			${*0}.Errors.AddRange($e)
			${*0}.Warnings.AddRange($w)
		}
		$c, $m = if (${*b}) {12, "Build ABORTED $BuildFile"}
		elseif (${*r} -eq 2) {12, 'Build FAILED'}
		elseif ($e) {14, 'Build completed with errors'}
		elseif ($w) {14, 'Build succeeded with warnings'}
		else {10, 'Build succeeded'}
		Write-Build $c "$m. $($t.Count) tasks, $($e.Count) errors, $($w.Count) warnings $((${*}.Elapsed = [DateTime]::Now - ${*}.Started))"
	}
}
}
