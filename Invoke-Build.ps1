
<#
Invoke-Build - Build Automation in PowerShell
Copyright (c) 2011-2014 Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
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

if ($MyInvocation.InvocationName -eq '.') {return}

function *FP($_) {
	$PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)
}

function *TE($M, $C = 0) {
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, $C, $null))
}

$BuildTask = $PSBoundParameters['Task']
$BuildFile = $PSBoundParameters['File']
${private:*Parameters} = $PSBoundParameters['Parameters']
${private:*Checkpoint} = $PSBoundParameters['Checkpoint']
${private:*Resume} = $PSBoundParameters['Resume']
${private:*cd} = *FP
${private:*cp} = $null
${private:*names} =
'Task', 'File', 'Parameters', 'Checkpoint', 'Result', 'Safe', 'Summary', 'Resume', 'WhatIf',
'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'ErrorVariable', 'WarningVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable'

try {
	if ($BuildTask -eq '**') {
		if (![System.IO.Directory]::Exists(($BuildFile = *FP $BuildFile))) {throw "Missing directory '$BuildFile'."}
		$BuildFile = @(Get-ChildItem -LiteralPath $BuildFile -Recurse *.test.ps1)
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
}
catch {
	*TE $_ 13
}

if (${*Parameters}) {return}

$_ = Get-Command -Name $BuildFile -CommandType ExternalScript -ErrorAction 1
if (!($_ = $_.Parameters) -or !$_.Count) {return}

${private:*r} = New-Object Management.Automation.RuntimeDefinedParameterDictionary
${private:*a} = New-Object Collections.ObjectModel.Collection[Attribute]
${*a}.Add((New-Object Management.Automation.ParameterAttribute))
foreach($_ in $_.Values) {
	if (${*names} -notcontains $_.Name) {
		${*r}.Add($_.Name, (New-Object Management.Automation.RuntimeDefinedParameter $_.Name, $_.ParameterType, ${*a}))
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
	$If = 1,
	$Inputs,
	$Outputs,
	$Data,
	$Done,
	$Source = $MyInvocation,
	[switch]$Partial
)
{
	${*}.All[$Name] = [PSCustomObject]@{
		Name = $Name
		Error = $null
		Started = $null
		Elapsed = $null
		Jobs = $1 = [System.Collections.ArrayList]@()
		Safe = $2 = [System.Collections.ArrayList]@()
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
	try {
		foreach($_ in $Jobs) {
			$r, $d = *RJ $_
			$null = $1.Add($r)
			if (1 -eq $d) {
				$null = $2.Add($r)
			}
		}
	}
	catch {
		*TE "Task '$Name': $_" 5
	}
}

#.ExternalHelp Invoke-Build-Help.xml
function New-BuildJob([Parameter(Mandatory=1)][string]$Name, [switch]$Safe)
{
	if ($Safe) {@{$Name = 1}} else {$Name}
}

#.ExternalHelp Invoke-Build-Help.xml
function Assert-Build([Parameter()]$Condition, [string]$Message) {
	if (!$Condition) {
		*TE "Assertion failed.$(if ($Message) {" $Message"})" 7
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
	try {
		$d = switch -regex ($Path) {
			'^\d+\.' {[Microsoft.Win32.Registry]::GetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$Path", 'MSBuildToolsPath', '')}
			'^Framework' {"$env:windir\Microsoft.NET\$Path"}
			default {*FP $Path}
		}
		if (![System.IO.Directory]::Exists($d)) {throw "Cannot resolve '$Path'."}
	}
	catch {
		*TE $_ 5
	}
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

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildVersion {[Version]'2.9.10'}

if ($MyInvocation.InvocationName -eq '.') {
	return @'
Invoke-Build 2.9.10
Copyright (c) 2011-2014 Roman Kuzmin

Add-BuildTask (task)
Assert-Build (assert)
Get-BuildError (error)
Get-BuildProperty (property)
Get-BuildVersion
Invoke-BuildExec (exec)
New-BuildJob (job)
Use-BuildAlias (use)
Write-Build
'@
}

Set-Alias assert Assert-Build
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias job New-BuildJob
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias

if (!$Host.UI -or !$Host.UI.RawUI -or 'Default Host', 'ServerRemoteHost' -contains $Host.Name) {
	function Write-Build($Color, [string]$Text) {$Text}
}

function Write-Warning($Message) {
	$PSCmdlet.WriteWarning($Message)
	$null = ${*}.Warnings.Add("WARNING: $Message")
}

function *My {
	$_.InvocationInfo.ScriptName -like '*\Invoke-Build.ps1'
}

function *SL($_ = $BuildRoot) {
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
		$null = $t.Safe.Add($N)
	}
}

filter *Try($T, $P = [System.Collections.Stack]@()) {
	if (!($r = ${*}.All[$_])) {
		$_ = "Missing task '$_'."
		throw $(if ($T) {*EI "Task '$($T.Name)': $_" $T} else {$_})
	}
	if ($P.Contains($r)) {
		throw *EI "Task '$($T.Name)': Cyclic reference to '$_'." $T
	}
	if ($j = foreach($_ in $r.Jobs) {if ($_ -is [string]) {$_}}) {
		$P.Push($r)
		$j | *Try $r $P
		$null = $P.Pop()
	}
}

function *CP {
	$_ = @{
		User = *UC Export-Build
		Task = $BuildTask
		File = $BuildFile
		Prm1 = ${*}.Parameters
		Prm2 = @{}
		Done = foreach($t in ${*}.All.Values) {if ($t.Elapsed) {$t.Name}}
	}
	$p = (Get-Command -Name $BuildFile -CommandType ExternalScript -ErrorAction 1).Parameters
	if ($p.Count) {
		foreach($k in $p.Keys) {
			$_.Prm2[$k] = Get-Variable -Name $k -Scope Script -ValueOnly
		}
	}
	$_ | Export-Clixml ${*}.Checkpoint
}

function *WE {
	Write-Build 14 (*II $Task)
	$null = ${*}.Errors.Add($_)
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
	${private:*p} = [System.Collections.ArrayList]@()
	${*i} = foreach($_ in ${*i}) {
		if ($_ -isnot [System.IO.FileInfo]) {$_ = [System.IO.FileInfo](*FP $_)}
		if (!$_.Exists) {throw "Missing Inputs item: '$_'."}
		$_
		$null = ${*p}.Add($_.FullName)
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
		$Task.Inputs = $i = [System.Collections.ArrayList]@()
		$Task.Outputs = $o = [System.Collections.ArrayList]@()
		foreach($_ in ${*i}) {
			if ($_.LastWriteTime -gt [System.IO.File]::GetLastWriteTime((*FP ($p = ${*o}[++$k])))) {
				$null = $i.Add(${*p}[$k]), $o.Add($p)
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
	$_, ${private:*p} = $args
	New-Variable -Name Task -Value ${*}.All[$_] -Option Constant
	${*p} = "${*p}/$($Task.Name)"

	if ($Task.Error) {
		Write-Build 8 "Task ${*p} failed."
		return
	}
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
			. *WE
			Write-Build 12 (*EI "ERROR: Task ${*p}: $_" $_)
		}
		else {
			Write-Build 11 "Done ${*p} $($Task.Elapsed)"
		}
		if ($Task.Done) {*UC $Task.Done}
		if (${*}.Checkpoint) {*CP}
	}
	catch {
		$Task.Elapsed = [DateTime]::Now - $Task.Started
		$Task.Error = $_
		. *WE
		throw
	}
	finally {
		$null = ${*}.Tasks.Add($Task)
		. *UC Exit-BuildTask
	}
}

function Enter-Build {} function Enter-BuildTask {} function Enter-BuildJob {}
function Exit-Build {} function Exit-BuildTask {} function Exit-BuildJob {}
function Export-Build {} function Import-Build {}

$ErrorActionPreference = 'Stop'
Set-Alias Invoke-Build ($_ = $MyInvocation.MyCommand.Path)
Set-Alias Invoke-Builds (Join-Path (Split-Path $_) Invoke-Builds.ps1)

if (!${*Parameters}) {
	foreach($_ in $PSBoundParameters.GetEnumerator()) {
		if (${*names} -notcontains $_.Key) {
			if (!${*Parameters}) {${*Parameters} = @{}}
			${*Parameters}[$_.Key] = $_.Value
		}
	}
}

if (${private:*0} = $PSCmdlet.SessionState.PSVariable.Get('*')) {
	${*0} = if (${*0}.Description -eq 'Invoke-Build') {${*0}.Value}
}
New-Variable * -Description Invoke-Build ([PSCustomObject]@{
	Tasks = [System.Collections.ArrayList]@()
	Errors = [System.Collections.ArrayList]@()
	Warnings = [System.Collections.ArrayList]@()
	All = ${private:*a} = [System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase)
	Parameters = $_ = ${*Parameters}
	Checkpoint = ${*Checkpoint}
	Started = [DateTime]::Now
	Elapsed = $null
	Error = $null
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

${private:*r} = 0
try {
	if ($BuildTask -eq '**') {
		$BuildTask = @('*'; $BuildTask -ne '**')
		foreach($_ in $BuildFile) {
			Invoke-Build $BuildTask $_.FullName
		}
		${*r} = 1
		return
	}

	*SL ($BuildRoot = Split-Path $BuildFile)
	if ($_ = if ($_) {. $BuildFile @_} else {. $BuildFile}) {
		Write-Warning "$BuildFile output:`r`n$_"
	}
	if (!${*a}.Count) {throw "No tasks in '$BuildFile'."}

	try {
		foreach(${private:**} in ${*a}.Values) {
			if (${**}.Before) {${**}.Before | *AB ${**}.Name 1}
			if (${**}.After) {${**}.After | *AB ${**}.Name}
		}
	}
	catch {
		throw *EI "Task '$(${**}.Name)': $_" ${**}
	}

	if (${*?}) {
		${*a}.Keys | *Try
		if ($BuildTask -eq '??') {
			${*a}
		}
		else {
			${*a}.Values | *TH @{}
		}
		return
	}

	if ($BuildTask -eq '*') {
		$BuildTask = :task foreach($_ in ${*a}.Keys) {
			foreach(${**} in ${*a}.Values) {
				if (${**}.Jobs -contains $_) {
					$_ | *Try
					continue task
				}
			}
			$_
		}
	}
	elseif (!$BuildTask -or '.' -eq $BuildTask) {
		$BuildTask = if (${*a}['.']) {'.'} else {${*a}.Item(0).Name}
	}
	Write-Build 11 "Build $($BuildTask -join ', ') $BuildFile"
	$BuildTask | *Try

	try {
		. *UC Enter-Build
		if (${*cp}) {
			foreach($_ in ${*cp}.Done) {
				${*a}[$_].Elapsed = [TimeSpan]::Zero
			}
			foreach($_ in ${*cp}.Prm2.GetEnumerator()) {
				Set-Variable -Name $_.Key -Value $_.Value
			}
			. *UC Import-Build ${*cp}.User
		}
		foreach($_ in $BuildTask) {
			*Task $_
		}
		if (${*Checkpoint}) {
			[System.IO.File]::Delete(${*Checkpoint})
		}
	}
	finally {
		. *UC Exit-Build
	}
	${*r} = 1
}
catch {
	${*r} = 2
	${*}.Error = $_
	if (!${*Safe}) {
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
			foreach($_ in ${*}.Tasks) {
				'{0,-16} {1} - {2}:{3}' -f $_.Elapsed, $_.Name, $_.InvocationInfo.ScriptName, $_.InvocationInfo.ScriptLineNumber
				if ($_ = $_.Error) {
					Write-Build 12 $(if (*My) {"ERROR: $_"} else {*EI "ERROR: $_" $_})
				}
			}
		}
		($w = ${*}.Warnings)
		if (${*0}) {
			${*0}.Tasks.AddRange($t)
			${*0}.Errors.AddRange($e)
			${*0}.Warnings.AddRange($w)
		}
		$c, $m = if (${*r} -eq 2) {12, 'Build FAILED'}
		elseif ($e) {14, 'Build completed with errors'}
		elseif ($w) {14, 'Build succeeded with warnings'}
		else {10, 'Build succeeded'}
		Write-Build $c "$m. $($t.Count) tasks, $($e.Count) errors, $($w.Count) warnings $((${*}.Elapsed = [DateTime]::Now - ${*}.Started))"
	}
}
}
