
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
	[switch]$WhatIf
)

#.ExternalHelp Invoke-Build-Help.xml
function Add-BuildTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)][object[]]$Jobs,
	[object[]]$After,
	[object[]]$Before,
	$If = 1,
	$Inputs,
	$Outputs,
	[switch]$Partial
)
{
	${*}.All[$Name] = [PSCustomObject]@{
		Name = $Name
		Error = $null
		Started = $null
		Elapsed = $null
		Job = $1 = [System.Collections.ArrayList]@()
		Try = $2 = [System.Collections.ArrayList]@()
		After = $After
		Before = $Before
		If = $If
		Inputs = $Inputs
		Outputs = $Outputs
		Partial = $Partial
		InvocationInfo = $MyInvocation
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
function New-BuildJob(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[switch]$Safe
)
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
function Get-BuildFile($Path) {
	if (($_ = [System.IO.Directory]::GetFiles($Path, '*.build.ps1')).Count -eq 1) {return $_}
	$_ -like '*\.build.ps1'
}

#.ExternalHelp Invoke-Build-Help.xml
function Get-BuildProperty([Parameter(Mandatory=1)][string]$Name, $Value) {
	if ($null -ne ($_ = $PSCmdlet.GetVariableValue($Name)) -or $null -ne ($_ = [Environment]::GetEnvironmentVariable($Name)) -or $null -ne ($_ = $Value)) {
		$_
	}
	else {
		*TE "Missing variable '$Name'." 13
	}
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
function Get-BuildVersion {[Version]'2.6.2'}

if ($MyInvocation.InvocationName -eq '.') {
	return @'
Invoke-Build 2.6.2
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

if (!$Host.UI -or !$Host.UI.RawUI -or 'Default Host', 'ServerRemoteHost' -contains $Host.Name) {
	function Write-Build($Color, [string]$Text) {$Text}
}

function Write-Warning($Message) {
	$PSCmdlet.WriteWarning($Message)
	$null = ${*}.Warnings.Add("WARNING: $Message")
}

function *TE($M, $C = 0) {
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, $C, $null))
}

function *My {
	$_.InvocationInfo.ScriptName -like '*\Invoke-Build.ps1'
}

function *FP($_) {
	$PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)
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
	elseif ($_ -isnot [hashtable] -or $_.Count -ne 1) {
		throw 'Invalid job.'
	}
	else {
		$_.Keys
		$_.Values
	}
}

function *Bad($B, $J, $X) {
	foreach($_ in $J) {
		if (($t = ${*}.All[$_]) -and $t.If -and $(if ($_ -eq $B) {$X -notcontains $_} else {*Bad $B $t.Job $t.Try})) {
			return 1
		}
	}
}

filter *AB($N, $B) {
	$r, $d = *RJ $_
	if (!($t = ${*}.All[$r])) {throw "Missing task '$r'."}
	$j = $t.Job
	$i = $j.Count
	if ($B) {
		for($k = -1; ++$k -lt $i -and $j[$k] -is [string]) {}
		$i = $k
	}
	$j.Insert($i, $N)
	if (1 -eq $d) {
		$null = $t.Try.Add($N)
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
	if ($j = foreach($_ in $r.Job) {if ($_ -is [string]) {$_}}) {
		$P.Push($r)
		$j | *Try $r $P
		$null = $P.Pop()
	}
}

function *IO {
	${private:**} = $args[0]

	if ((${private:*i} = ${**}.Inputs) -is [scriptblock]) {
		*SL
		${*i} = @(& ${*i})
	}
	*SL
	${private:*p} = [System.Collections.ArrayList]@()
	${*i} = foreach($_ in ${*i}) {
		if ($_ -isnot [System.IO.FileInfo]) {$_ = [System.IO.FileInfo](*FP $_)}
		if (!$_.Exists) {throw "Missing input file '$_'."}
		$_
		$null = ${*p}.Add($_.FullName)
	}
	if (!${*p}) {return 'Skipping empty input.'}

	${private:*o} = ${**}.Outputs
	if (${**}.Partial) {
		${*o} = @(
			if (${*o} -is [scriptblock]) {
				${*p} | & ${*o}
				*SL
			}
			else {
				${*o}
			}
		)
		if (${*p}.Count -ne ${*o}.Count) {throw "Different input/output: $(${*p}.Count)/$(${*o}.Count)."}

		$k = -1
		${**}.Inputs = $i = [System.Collections.ArrayList]@()
		${**}.Outputs = $o = [System.Collections.ArrayList]@()
		foreach($_ in ${*i}) {
			if ($_.LastWriteTime -gt [System.IO.File]::GetLastWriteTime((*FP ($p = ${*o}[++$k])))) {
				$null = $i.Add(${*p}[$k]), $o.Add($p)
			}
		}
		if ($i) {return}
	}
	else {
		if (${*o} -is [scriptblock]) {
			${**}.Outputs = ${*o} = & ${*o}
			*SL
		}
		if (!${*o}) {throw 'Empty output.'}

		${**}.Inputs = ${*p}
		$m = (${*i} | .{process{$_.LastWriteTime.Ticks}} | Measure-Object -Maximum).Maximum
		foreach($_ in ${*o}) {
			if ($m -gt [System.IO.File]::GetLastWriteTime((*FP $_)).Ticks) {return}
		}
	}
	'Skipping up-to-date output.'
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

	$p = (Get-Command -Name $BuildFile -CommandType ExternalScript).Parameters
	if ($p.Count) {
		foreach($k in $p.Keys) {
			$v = Get-Variable -Name $k -Scope Script
			$_.Prm2[$v.Name] = $v.Value
		}
	}

	$_ | Export-Clixml ${*}.Checkpoint
}

function *Task {
	${private:**}, ${private:*p} = $args

	${**} = ${*}.All[${**}]
	${*p} = "${*p}/$(${**}.Name)"
	if (${**}.Error) {
		Write-Build 8 "${*p} failed."
		return
	}
	if (${**}.Elapsed) {
		Write-Build 8 "Done ${*p}"
		return
	}

	if ((${private:*x} = ${**}.If) -is [scriptblock] -and !$WhatIf) {
		*SL
		try {
			${*x} = & ${*x}
		}
		catch {
			${**}.Error = $_
			throw
		}
	}
	if (!${*x}) {
		Write-Build 8 "${*p} skipped."
		return
	}

	${private:*n} = 0
	${private:*a} = ${**}.Job
	${private:*i} = [int]($null -ne ${**}.Inputs)
	${**}.Started = [DateTime]::Now
	try {
		. *UC Enter-BuildTask ${**}
		foreach(${private:*j} in ${*a}) {
			++${*n}
			if (${*j} -is [string]) {
				try {
					*Task ${*j} ${*p}
				}
				catch {
					if (*Bad ${*j} $BuildTask) {throw}
					Write-Build 12 (*EI "ERROR: $_" $_)
				}
				continue
			}

			${private:*m} = "${*p} (${*n}/$(${*a}.Count))"
			Write-Build 11 "${*m}:"
			if ($WhatIf) {
				${*j}
				continue
			}

			if (1 -eq ${*i}) {${*i} = *IO ${**}}
			if (${*i}) {
				Write-Build 11 ${*i}
				continue
			}

			try {
				*SL
				. Enter-BuildJob ${**} ${*n}
				*SL
				if (0 -eq ${*i}) {
					& ${*j}
				}
				else {
					$Inputs = ${**}.Inputs
					$Outputs = ${**}.Outputs
					if (${**}.Partial) {
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
				${**}.Error = $_
				throw
			}
			finally {
				*SL
				. Exit-BuildJob ${**} ${*n}
			}
			if (${*a}.Count -ge 2) {
				Write-Build 11 "Done ${*m}"
			}
		}
		${**}.Elapsed = $_ = [DateTime]::Now - ${**}.Started
		Write-Build 11 "Done ${*p} $_"
		if (${*}.Checkpoint) {*CP}
	}
	catch {
		Write-Build 14 (*II ${**})
		${**}.Error = $_
		${**}.Elapsed = [DateTime]::Now - ${**}.Started
		${*x} = "ERROR: Task ${*p}: $_"
		$null = ${*}.Errors.Add($(if (*My) {${*x}} else {*EI ${*x} $_}))
		throw
	}
	finally {
		$null = ${*}.Tasks.Add(${**})
		. *UC Exit-BuildTask ${**}
	}
}

$ErrorActionPreference = 'Stop'
${private:*cd} = *FP
${private:*cp} = $null
if ($Task -eq '**') {
	if (![System.IO.Directory]::Exists(($File = *FP $File))) {throw "Missing directory '$File'."}
	$BuildFile = @(Get-ChildItem -LiteralPath $File -Recurse *.test.ps1)
	$BuildRoot = ${*cd}
}
else {
	if ($Checkpoint) {$Checkpoint = *FP $Checkpoint}
	try {
		if ($File) {
			if (!([System.IO.File]::Exists(($BuildFile = *FP $File)))) {throw "Missing script '$BuildFile'."}
		}
		elseif ($Checkpoint -and !($Task -or $Parameters)) {
			${private:*cp} = Import-Clixml $Checkpoint
			$Task = ${*cp}.Task
			$BuildFile = ${*cp}.File
			$Parameters = ${*cp}.Prm1
		}
		elseif (!($BuildFile = Get-BuildFile ${*cd})) {
			throw 'Missing default script.'
		}
	}
	catch {
		*TE $_ 13
	}
	$BuildRoot = Split-Path $BuildFile
}

function Enter-Build {} function Enter-BuildTask {} function Enter-BuildJob {}
function Exit-Build {} function Exit-BuildTask {} function Exit-BuildJob {}
function Export-Build {} function Import-Build {}

Set-Alias assert Assert-Build
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias job New-BuildJob
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias

$_ = $MyInvocation.MyCommand.Path
Set-Alias Invoke-Build $_
Set-Alias Invoke-Builds (Join-Path (Split-Path $_) Invoke-Builds.ps1)

if (${private:*0} = $PSCmdlet.SessionState.PSVariable.Get('*')) {
	${*0} = if (${*0}.Description -eq 'Invoke-Build') {${*0}.Value}
}
New-Variable * -Description Invoke-Build ([PSCustomObject]@{
	Tasks = [System.Collections.ArrayList]@()
	Errors = [System.Collections.ArrayList]@()
	Warnings = [System.Collections.ArrayList]@()
	All = ${private:*a} = [System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase)
	Parameters = $_ = $Parameters
	Checkpoint = $Checkpoint
	Started = [DateTime]::Now
	Elapsed = $null
	Error = $null
})
if (${private:*?} = $Task -eq '??' -or $Task -eq '?') {
	$WhatIf = $true
}
$BuildTask = $Task
${private:*Safe} = $Safe
if ($Result) {
	if ($Result -is [string]) {
		New-Variable -Force -Scope 1 $Result ${*}
	}
	else {
		$Result.Value = ${*}
	}
}
Remove-Variable Task, File, Parameters, Checkpoint, Result, Safe

${private:*r} = 0
try {
	if ($BuildTask -eq '**') {
		$BuildTask = @('*'; $BuildTask -ne '**')
		foreach($_ in $BuildFile) {
			Invoke-Build $BuildTask $_.FullName
		}
	}
	else {
		*SL
		if ($_ = if ($_) {. $BuildFile @_} else {. $BuildFile}) {
			Write-Warning "$BuildFile output:`n$_"
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
				foreach($_ in ${*a}.Values) {"$($_.InvocationInfo.ScriptName)($($_.InvocationInfo.ScriptLineNumber)): $($_.Name)"}
			}
			return
		}

		if ($BuildTask -eq '*') {
			$BuildTask = :task foreach($_ in ${*a}.Keys) {
				foreach(${**} in ${*a}.Values) {
					if (${**}.Job -contains $_) {
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
			if ($_ = ${*}.Checkpoint) {
				[System.IO.File]::Delete($_)
			}
		}
		finally {
			. *UC Exit-Build
		}
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
		${*}.Elapsed = $_ = [DateTime]::Now - ${*}.Started
		$t = ${*}.Tasks
		($e = ${*}.Errors)
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
		Write-Build $c "$m. $($t.Count) tasks, $($e.Count) errors, $($w.Count) warnings $_"
	}
}
