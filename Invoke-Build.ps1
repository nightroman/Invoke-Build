
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

#.ExternalHelp Invoke-Build-Help.xml
param(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)]$File,
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
		if (($f = [System.IO.Directory]::GetFiles($Path, '*.build.ps1')).Length -eq 1) {return $f}
		if ($_ = $f -match '[\\/]\.build\.ps1$') {return $_}
		if ($f.Length -ge 2) {throw "Ambiguous default script in '$Path'."}
		if ([System.IO.File]::Exists(($_ = $env:InvokeBuildGetFile)) -and ($_ = & $_ $Path)) {return $_}
	} while($Path = Split-Path $Path)
}

function *Path($P) {
	$PSCmdlet.GetUnresolvedProviderPathFromPSPath($P)
}

function *Die($M, $C=0) {
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, $C, $null))
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
	Checkpoint = $PSBoundParameters['Checkpoint']
	Safe = $PSBoundParameters['Safe']
	Summary = $PSBoundParameters['Summary']
	CD = *Path
	DP = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	SP = $null
	CP = $null
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
	Export = $null
	Import = $null
	Header = {Write-Build 11 "Task $($args[0])"}
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

if (${*}.Checkpoint) {${*}.Checkpoint = *Path ${*}.Checkpoint}
if ($PSBoundParameters['Resume']) {
	if (!${*}.Checkpoint) {throw 'Checkpoint must be defined for Resume.'}
	${*}.CP = $_ = try {Import-Clixml ${*}.Checkpoint} catch {throw 'Invalid checkpoint file?'}
	$BuildTask = $_.Task
	$BuildFile = $_.File
	${*}.SP = $_.Prm1
}
elseif ($BuildFile) {
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
	$r = 'Task', 'File', 'Checkpoint', 'Result', 'Safe', 'Summary', 'Resume', 'WhatIf'
	foreach($p in $_.Values) {
		if ($c -notcontains ($_ = $p.Name)) {
			if ($r -contains $_) {throw "Script uses reserved parameter '$_'."}
			${*}.DP.Add($_, (New-Object System.Management.Automation.RuntimeDefinedParameter $_, $p.ParameterType, $a))
		}
	}
	${*}.DP
}}

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
	if ($_ = ${*}.All[$Name]) {${*}.Redefined += $_}
	${*}.All[$Name] = [PSCustomObject]@{
		Name = $Name
		Error = $null
		Started = $null
		Elapsed = $null
		Jobs = $1 = [System.Collections.Generic.List[object]]@()
		Safe = $2 = [System.Collections.Generic.List[object]]@()
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
	trap {*Die "Task '$Name': $_" 5}
	foreach($_ in $Jobs) {
		$r, $d = *Job $_
		if ($1 -contains $r) {${*}.Doubles += ,($Name, $r)}
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
		*Die "Assertion failed.$(if ($Message) {" $Message"})" 7
	}
}

#.ExternalHelp Invoke-Build-Help.xml
function Assert-BuildEquals([Parameter()]$A, $B) {
	if (![Object]::Equals($A, $B)) {
		*Die @"
Objects are not equal:
A:$(if ($null -ne $A) {" $A [$($A.GetType())]"})
B:$(if ($null -ne $B) {" $B [$($B.GetType())]"})
"@ 7
	}
}

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildError([Parameter(Mandatory=1)][string]$Task) {
	if (!($_ = ${*}.All[$Task])) {
		*Die "Missing task '$Task'." 13
	}
	$_.Error
}

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildProperty([Parameter(Mandatory=1)][string]$Name, $Value) {
	${*n} = $Name
	${*v} = $Value
	Remove-Variable Name, Value
	if (($null -ne ($_ = $PSCmdlet.GetVariableValue(${*n})) -and '' -ne $_) -or ($_ = [Environment]::GetEnvironmentVariable(${*n}))) {return $_}
	if ($null -eq ${*v}) {*Die "Missing property '${*n}'." 13}
	${*v}
}

#.ExternalHelp Invoke-Build-Help.xml
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

#.ExternalHelp Invoke-Build-Help.xml
function Invoke-BuildExec([Parameter(Mandatory=1)][scriptblock]$Command, [int[]]$ExitCode=0) {
	${private:*c} = $Command
	${private:*x} = $ExitCode
	Remove-Variable Command, ExitCode
	& ${*c}
	if (${*x} -notcontains $global:LastExitCode) {
		*Die "Command {${*c}} exited with code $global:LastExitCode." 8
	}
}

#.ExternalHelp Invoke-Build-Help.xml
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

#.ExternalHelp Invoke-Build-Help.xml
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

#.ExternalHelp Invoke-Build-Help.xml
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
try {
	$null = Write-Build 0
}
catch {
	function Write-Build($Color, [string]$Text) {$Text}
}

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildVersion {[Version]'3.6.5'}

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
	if ($J -is [scriptblock] -or $J -is [string]) {
		$J
	}
	elseif ($J -is [hashtable] -and $J.Count -eq 1) {
		$J.Keys
		$J.Values
	}
	else {throw 'Invalid job.'}
}

function *Unsafe($N, $J, $X) {
	foreach($_ in $J) {
		if (($t = ${*}.All[$_]) -and $t.If -and $(if ($_ -eq $N) {$X -notcontains $_} else {*Unsafe $N $t.Jobs $t.Safe})) {
			return 1
		}
	}
}

function *Amend([Parameter()]$X, $J, $B) {
	trap {*Die (*Error "Task '$n': $_" $X) 5}
	$n = $X.Name
	foreach($_ in $J) {
		$r, $d = *Job $_
		if (!($t = ${*}.All[$r])) {throw "Missing task '$r'."}
		$j = $t.Jobs
		$i = $j.Count
		if ($B) {
			for($k = -1; ++$k -lt $i -and $j[$k] -is [string]) {}
			$i = $k
		}
		$j.Insert($i, $n)
		if (1 -eq $d) {
			$t.Safe.Add($n)
		}
	}
}

function *Check([Parameter()]$J, $T, $P=@()) {
	foreach($_ in $J) { if ($_ -is [string]) {
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

function *Save {
	Export-Clixml ${*}.Checkpoint -InputObject @{
		User = *Run ${*}.Export
		Task = $BuildTask
		File = $BuildFile
		Prm1 = ${*}.SP
		Prm2 = $(
			$r = @{}
			foreach($_ in ${*}.DP.Keys) {
				$r[$_] = Get-Variable -Name $_ -Scope Script -ValueOnly
			}
			$r
		)
		Done = @(foreach($t in ${*}.All.Values) {if ($t.Elapsed) {$t.Name}})
	}
}

function *AddError($T) {
	${*}.Errors.Add([PSCustomObject]@{Error = $_; File = $BuildFile; Task = $T})
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
	foreach($_ in $A.Values) {foreach($_ in $_.Jobs) {if ($_ -is [string]) {$h[$_] = 1}}}
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
		if (!$_.Exists) {throw "Missing Inputs item: '$_'."}
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
	New-Variable -Name Task -Option Constant -Value (${*}.Task = ${*}.All[$args[0]])
	${private:*p} = $args[1] + '/' + $Task.Name

	if ($Task.Elapsed) {
		Write-Build 8 "Done ${*p}"
		return
	}

	if (${*}.Checkpoint) {*Save}
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

	${private:*i} = , [int]($null -ne $Task.Inputs)
	$Task.Started = [DateTime]::Now
	try {
		. *Run ${*}.EnterTask
		foreach(${private:*j} in $Task.Jobs) {
			if (${*j} -is [string]) {
				try {
					*Task ${*j} ${*p}
				}
				catch {
					if (*Unsafe ${*j} $BuildTask) {throw}
					*AddError ${*}.All[${*j}]
					Write-Build 12 "ERROR: $(if (*My) {$_} else {*Error $_ $_})"
				}
				continue
			}

			& ${*}.Header ${*p}
			if ($WhatIf) {
				${*j}
				continue
			}

			if (1 -eq ${*i}[0]) {
				${*i} = *IO
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
			Write-Build 12 "ERROR: $(*Error $_ $_)"
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
		throw
	}
	finally {
		${*}.Tasks.Add($Task)
		. *Run ${*}.ExitTask
	}
}

Set-Alias assert Assert-Build
Set-Alias equals Assert-BuildEquals
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias job New-BuildJob
Set-Alias property Get-BuildProperty
Set-Alias requires Test-BuildAsset
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias
Set-Alias Invoke-Build ($_ = $MyInvocation.MyCommand.Path)
$_ = Split-Path $_
Set-Alias Invoke-Builds (Join-Path $_ Invoke-Builds.ps1)
Set-Alias Resolve-MSBuild (Join-Path $_ Resolve-MSBuild.ps1)

if ($MyInvocation.InvocationName -eq '.') {
	if ($_ = $MyInvocation.ScriptName) {
		$ErrorActionPreference = 'Stop'
		$BuildFile = $_
		*SL ($BuildRoot = if ($Task) {*Path $Task} else {Split-Path $_})
	}
	Remove-Variable Task, File, Checkpoint, Result, Safe, Summary, Resume, WhatIf
	return
}

function Write-Warning([Parameter()]$Message) {
	$PSCmdlet.WriteWarning($Message)
	${*}.Warnings.Add([PSCustomObject]@{Message = $Message; File = $BuildFile; Task = ${*}.Task})
}

$ErrorActionPreference = 'Stop'
if (!${*}.SP) {
	${*}.SP = @{}
	foreach($_ in $PSBoundParameters.Keys) {
		if (${*}.DP.ContainsKey($_)) {
			${*}.SP[$_] = $PSBoundParameters[$_]
		}
	}
}
if (${*}.Q = $BuildTask -eq '??' -or $BuildTask -eq '?') {
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
Remove-Variable Task, File, Checkpoint, Result, Safe, Summary, Resume

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
	function Export-Build([Parameter()][scriptblock]$Script) {${*}.Export = $Script}
	function Import-Build([Parameter()][scriptblock]$Script) {${*}.Import = $Script}
	function Set-BuildHeader([Parameter()][scriptblock]$Script) {${*}.Header = $Script}

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
		if (${*}.CP) {
			foreach($_ in ${*}.CP.Done) {
				${**}[$_].Elapsed = [TimeSpan]::Zero
			}
			foreach($_ in ${*}.CP.Prm2.GetEnumerator()) {
				Set-Variable $_.Key $_.Value
			}
			. *Run ${*}.Import ${*}.CP.User
		}
		foreach($_ in $BuildTask) {
			*Task $_ ''
		}
		${*}.Task = $null
		if (${*}.Checkpoint) {
			[System.IO.File]::Delete(${*}.Checkpoint)
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
	*AddError ${*}.Task
	if ($_.FullyQualifiedErrorId -eq 'PositionalParameterNotFound,Add-BuildTask') {
		Write-Warning 'Check task positional parameters: a name and comma separated jobs.'
	}
	if (${*}.Safe) {
		Write-Build 12 (*Error "ERROR: $_" $_)
	}
	else {
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
