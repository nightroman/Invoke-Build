<#
Copyright (c) Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
#>

#.ExternalHelp Help.xml
param(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)]$File,
	$Result,
	[switch]$Safe,
	[switch]$Summary,
	[switch]$WhatIf
)

dynamicparam {
trap {*Die $_ 5}
function *Die($M, $C=0) {$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, $C, $null))}

Set-Alias assert Assert-Build
Set-Alias equals Assert-BuildEquals
Set-Alias exec Invoke-BuildExec
Set-Alias print Write-Build
Set-Alias property Get-BuildProperty
Set-Alias remove Remove-BuildItem
Set-Alias requires Test-BuildAsset
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias
Set-Alias Invoke-Build ([System.IO.Path]::Combine($PSScriptRoot, 'Invoke-Build.ps1'))
Set-Alias Build-Parallel ([System.IO.Path]::Combine($PSScriptRoot, 'Build-Parallel.ps1'))
Set-Alias Resolve-MSBuild ([System.IO.Path]::Combine($PSScriptRoot, 'Resolve-MSBuild.ps1'))

#.ExternalHelp Help.xml
function Add-BuildTask(
	[Parameter(Position=0, Mandatory=1)][string]$Name,
	[Parameter(Position=1)]$Jobs,
	[string[]]$After,
	[string[]]$Before,
	$If=-9,
	$Inputs,
	$Outputs,
	$Data,
	$Done,
	$Source=$MyInvocation,
	[switch]$Partial
)
{
	trap {*Die "Task '$Name': $_" 5}
	if (${*}.A -eq 0) {throw 'Cannot add tasks.'}
	if ($Jobs -is [hashtable]) {
		if ($PSBoundParameters.get_Count() -ne 2) {throw 'Invalid parameters.'}
		Add-BuildTask $Name @Jobs -Source:$Source
		return
	}
	if ($Name[0] -eq '?') {throw 'Invalid task name.'}
	$B1 = ${*}.B1
	if ($PX = $B1.PX) {
		filter PX {
			$r = $_.TrimStart('?')
			if (!$r.Contains('::') -and $r -ne '.' -and !${*}.All[$r]) {$r = $PX+$r}
			if ($_[0] -eq '?') {"?$r"} else {$r}
		}
		$Name = $Name | PX
		if ($After) {$After = $After | PX}
		if ($Before) {$Before = $Before | PX}
	}
	if ($_ = ${*}.All[$Name]) {
		${*}.Redefined += $_
		${*}.All.Remove($Name)
	}
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
		B1 = $B1
	}
	if ($Jobs) {$2 = @(); foreach($j in $Jobs) {
		$r, $s = *Job $j
		if ($r -is [string]) {
			if ($PX) {$r = $r | PX}
			if ($r -in $2) {${*}.Doubles += ,($Name, $r)} else {$2 += $r}
			if ($s) {$r = "?$r"}
		}
		$1.Add($r)
	}}
}

#.ExternalHelp Help.xml
function Assert-Build([Parameter()]$Condition, [string]$Message) {
	if (!$Condition) {
		*Die "Assertion failed.$(if ($Message) {" $Message"})" 7
	}
}

#.ExternalHelp Help.xml
function Assert-BuildEquals([Parameter()]$A, $B) {
	if (![Object]::Equals($A, $B)) {
		*Die @"
Objects are not equal:
A:$(if ($null -ne $A) {" $A [$($A.GetType())]"})
B:$(if ($null -ne $B) {" $B [$($B.GetType())]"})
"@ 7
	}
}

#.ExternalHelp Help.xml
function Confirm-Build([Parameter()][string]$Query, [string]$Caption=$Task.Name) {
	$PSCmdlet.ShouldContinue($Query, $Caption)
}

#.ExternalHelp Help.xml
function Get-BuildError([Parameter(Mandatory=1)][string]$Task) {
	if (!($_ = ${*}.All[$Task])) {
		*Die "Missing task '$Task'." 5
	}
	$_.Error
}

#.ExternalHelp Help.xml
function Get-BuildFile($Path, [switch]$Here) {
	do {
		if (($f = [System.IO.Directory]::GetFiles($Path, '*.build.ps1')).Length -eq 1) {return $f}
		if ($f) {return $($f | Sort-Object)[0]}
		if (($c = $env:InvokeBuildGetFile) -and ($f = & $c $Path)) {return $f}
	} while(!$Here -and ($Path = Split-Path $Path))
}

#.ExternalHelp Help.xml
function Get-BuildProperty([Parameter(Mandatory=1)][string]$Name, $Value, [switch]$Boolean) {
	${*n} = $Name
	${*v} = $Value
	Remove-Variable Name, Value
	$_ = if (($null -ne ($_ = $PSCmdlet.GetVariableValue(${*n})) -and '' -ne $_) -or ($_ = [Environment]::GetEnvironmentVariable(${*n}))) {$_}
	elseif ($null -eq ${*v}) {*Die "Missing property '${*n}'." 13}
	else {${*v}}
	if ($Boolean) {if (1 -eq $_) {$true} elseif (0 -eq $_) {$false} else {[System.Convert]::ToBoolean($_)}} else {$_}
}

#.ExternalHelp Help.xml
function Get-BuildSynopsis([Parameter(Mandatory=1)]$Task, $Hash=${*}.H) {
	$f = ($I = $Task.InvocationInfo).ScriptName
	if (!($d = $Hash[$f])) {
		$Hash[$f] = $d = @{T = Get-Content -LiteralPath $f; C = @{}}
		foreach($_ in [System.Management.Automation.PSParser]::Tokenize($d.T, [ref]$null)) {
			if ($_.Type -eq 15) {$d.C[$_.EndLine] = $_.Content}
		}
	}
	for($n = $I.ScriptLineNumber; --$n -ge 1) {
		if ($c = $d.C[$n]) {if ($c -match '(?m)^\s*(?:#*\s*Synopsis\s*:|\.Synopsis\s*^)(.*)') {return $Matches[1].Trim()}}
		elseif ($d.T[$n - 1].Trim()) {break}
	}
}

#.ExternalHelp Help.xml
function Get-BuildVersion([Parameter(Mandatory=1)][string]$Path, [Parameter(Mandatory=1)]$Regex) {
	trap {*Die $_ 5}
	foreach($_ in [System.IO.File]::ReadAllLines($PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path))) {
		if ($_ -match $Regex) {
			return $Matches[1]
		}
	}
	throw "Cannot find version in '$Path'."
}

#.ExternalHelp Help.xml
function Invoke-BuildExec([Parameter(Mandatory=1)][scriptblock]$Command, [int[]]$ExitCode=0, [string]$ErrorMessage, [switch]$Echo, [switch]$StdErr) {
	${private:*c} = $Command
	${private:*x} = $ExitCode
	${private:*m} = $ErrorMessage
	${private:*v} = $Echo
	${private:*s} = $StdErr
	${private:*e} = ''
	Remove-Variable Command, ExitCode, ErrorMessage, Echo, StdErr
	if (${*v}) {
		*Echo ${*c}
	}

	$global:LastExitCode = 0
	if (${*s}) {
		$ErrorActionPreference = 2
		try {
			& ${*c} 2>&1 | .{process{
				if ($_ -is [System.Management.Automation.ErrorRecord]) {
					$_ = $_.Exception.Message
					${*e} += "`n$_"
				}
				$_
			}}
		}
		catch {throw}
	}
	else {
		& ${*c}
	}

	if (${*x} -notcontains $global:LastExitCode) {
		*Die "$(if (${*m}) {"${*m} "})Command exited with code $global:LastExitCode. {${*c}}${*e}" 8
	}
}

#.ExternalHelp Help.xml
function Remove-BuildItem([Parameter(Mandatory=1)][string[]]$Path) {
	if ($Path -match '^[.*/\\]*$') {*Die 'Not allowed paths.' 5}
	$v = $PSBoundParameters['Verbose']
	$p = @{Force=$true; Recurse=$true}
	if ($PSVersionTable.PSVersion -ge ([version]'7.4')) {$p.ProgressAction='Ignore'}
	try {
		foreach($_ in $Path) {
			if (Get-Item $_ -Force -ErrorAction 0) {
				if ($v) {Write-Verbose "remove: removing $_" -Verbose}
				Remove-Item $_ @p
			}
			elseif ($v) {Write-Verbose "remove: skipping $_" -Verbose}
		}
	}
	catch {
		*Die $_
	}
}

#.ExternalHelp Help.xml
function Set-BuildFooter([Parameter()][scriptblock]$Script) {
	${*}.Footer = $Script
}

#.ExternalHelp Help.xml
function Set-BuildHeader([Parameter()][scriptblock]$Script) {
	${*}.Header = $Script
}

#.ExternalHelp Help.xml
function Test-BuildAsset(
	[ValidateNotNullOrEmpty()][string[]][Parameter(Position=0)]$Variable,
	[ValidateNotNullOrEmpty()][string[]]$Environment,
	[ValidateNotNullOrEmpty()][string[]]$Property,
	[ValidateNotNullOrEmpty()][string[]]$Path
) {
	${*v} = $Variable
	${*e} = $Environment
	${*p} = $Property
	${*f} = $Path
	Remove-Variable Variable, Environment, Property, Path
	foreach($_ in ${*v}) {
		if ($null -eq ($$ = $PSCmdlet.GetVariableValue($_)) -or '' -eq $$) {*Die "Missing variable '$_'." 13}
	}
	foreach($_ in ${*e}) {
		if (!([Environment]::GetEnvironmentVariable($_))) {*Die "Missing environment variable '$_'." 13}
	}
	foreach($_ in ${*p}) {
		if ('' -eq (Get-BuildProperty $_ '')) {*Die "Missing property '$_'." 13}
	}
	foreach($_ in ${*f}) {
		if (!(Test-Path -LiteralPath $_)) {*Die "Missing path '$_'." 13}
	}
}

#.ExternalHelp Help.xml
function Use-BuildAlias([Parameter(Mandatory=1)][string]$Path, [string[]]$Name) {
	trap {*Die $_ 5}
	$d = switch -regex ($Path) {
		'^\*|^\d+\.' {Split-Path (Resolve-MSBuild $_)}
		^Framework {"$env:windir\Microsoft.NET\$_"}
		default {*Path $_}
	}
	if (![System.IO.Directory]::Exists($d)) {throw "Cannot resolve '$Path'."}
	foreach($_ in $Name) {
		Set-Alias $_ (Join-Path $d $_) -Scope 1
	}
}

#.ExternalHelp Help.xml
function Use-BuildEnv([Parameter(Mandatory=1)][hashtable]$Env, [Parameter(Mandatory=1)][scriptblock]$Script) {
	${private:*e} = @{}
	${private:*s} = $Script
	function *set($n, $v) {
		[Environment]::SetEnvironmentVariable($n, $(if ($null -eq $v) {[System.Management.Automation.Language.NullString]::Value} else {$v}))
	}
	foreach($_ in $Env.GetEnumerator()) {
		${*e}[$_.Key] = [Environment]::GetEnvironmentVariable($_.Key)
		*set $_.Key $_.Value
	}
	Remove-Variable Env, Script
	try {
		& ${*s}
	}
	finally {
		foreach($_ in ${*e}.GetEnumerator()) {
			*set $_.Key $_.Value
		}
	}
}

#.ExternalHelp Help.xml
function Write-Build([ConsoleColor]$Color, [string]$Text) {
	*Write $Color ($Text -split '\r\n|[\r\n]')
}

function *Msg($M, $I) {
	"$M`n$(*At $I)"
}

function *Path($P) {
	$PSCmdlet.GetUnresolvedProviderPathFromPSPath($P)
}

if ($PSVersionTable.PSVersion -ge [Version]'7.2' -and $PSStyle.OutputRendering -ne 'PlainText' -and !$env:MSBuildLoadMicrosoftTargetsReadOnly) {
	function *Write($C, $T) {
		$f = "`e[$((30,34,32,36,31,35,33,37,90,94,92,96,91,95,93,97)[$C])m{0}`e[0m"
		foreach($_ in $T) {
			$f -f $_
		}
	}
}
else {
	function *Write($C, $T) {
		$i = $Host.UI.RawUI
		$_ = $i.ForegroundColor
		try {
			$i.ForegroundColor = $C
			$T
		}
		finally {
			$i.ForegroundColor = $_
		}
	}
	try {
		$null = *Write 0
	}
	catch {
		function *Write {$args[1]}
	}
}

### init
if ($MyInvocation.InvocationName -eq '.') {return}
${private:*p} = if ($_ = $PSCmdlet.SessionState.PSVariable.Get('*')) {if ($_.Description -eq 'IB') {$_.Value}}
New-Variable * -Description IB ([PSCustomObject]@{
	All = [ordered]@{}
	Tasks = [System.Collections.Generic.List[object]]@()
	Errors = [System.Collections.Generic.List[object]]@()
	Warnings = [System.Collections.Generic.List[object]]@()
	Redefined = @()
	Doubles = @()
	Started = [DateTime]::Now
	Elapsed = $null
	Error = 'Invalid arguments.'
	Task = $null
	File = $BuildFile = $PSBoundParameters['File']
	Safe = $PSBoundParameters['Safe']
	Summary = $PSBoundParameters['Summary']
	CD = $OriginalLocation = *Path
	DP = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
	BB = [System.Collections.Generic.List[object]]@()
	B1 = $null
	P = ${*p}
	A = 1
	B = 0
	Q = 0
	H = @{}
	Header = if (${*p}) {${*p}.Header} else {{print 11 "Task $($args[0])"}}
	Footer = if (${*p}) {${*p}.Footer} else {{print 11 "Done $($args[0]) $($Task.Elapsed)"}}
	Data = @{}
	XBuild = $null
	XCheck = $null
})

if ($_ = $PSBoundParameters['Result']) {
	if ($_ -is [string]) {
		New-Variable $_ ${*} -Scope 1 -Force
	}
	elseif ($_ -is [hashtable]) {
		${*}.XBuild = $_['XBuild']
		${*}.XCheck = $_['XCheck']
		$_.Value = ${*}
	}
	else {throw 'Invalid parameter Result.'}
}

function *BB($FS, $PX, $BR) {
	$_ = if ($FS -is [string]) {$FS} else {$FS.File}
	@{FS=$FS; PX=$PX; BR=@(if ($_) {Split-Path $_} else {${*}.CD}; $BR); DP=@{}; EnterBuild=$null; ExitBuild=$null; EnterTask=$null; ExitTask=$null; EnterJob=$null; ExitJob=$null}
}

$BuildTask = $PSBoundParameters['Task']
if ($BuildFile -is [scriptblock]) {
	${*}.BB.Add((*BB $BuildFile '' @()))
	$BuildFile = $BuildFile.File
	return
}

if ($BuildTask -eq '**') {
	if (![System.IO.Directory]::Exists(($_ = *Path $BuildFile))) {throw "Missing directory '$_'."}
	$BuildFile = @(Get-ChildItem -LiteralPath $_ -Filter *.test.ps1 -Recurse -Force)
	return
}

if ($BuildFile) {
	if (![System.IO.File]::Exists(($BuildFile = *Path $BuildFile))) {
		if (![System.IO.Directory]::Exists($BuildFile)) {throw "Missing script '$BuildFile'."}
		if (!($_ = Get-BuildFile $BuildFile -Here)) {throw "Missing script in '$BuildFile'."}
		$BuildFile = $_
	}
}
elseif (!($BuildFile = Get-BuildFile ${*}.CD)) {
	throw 'Missing default script.'
}
${*}.File = $BuildFile

### param
function *DP($FS, $PX, $BR) {
	if (!($p = (Get-Command $FS -ErrorAction 1).Parameters)) {throw & $FS}
	$b = *BB $FS $PX $BR
	if ($p.get_Count()) {
		$c = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'ErrorVariable', 'WarningVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'InformationAction', 'InformationVariable', 'ProgressAction'
		$r = 'Task', 'File', 'Result', 'Safe', 'Summary', 'WhatIf'
		:param foreach($p in $p.get_Values()) {
			if (($n = $p.Name) -in $c) {continue}
			if ($n -in $r) {throw "Script uses reserved parameter '$n'."}
			foreach ($a in $p.Attributes) {
				if ($a -is [System.Management.Automation.ValidateScriptAttribute]) {if ($n -eq 'Extends') {
					foreach($s in & $a.ScriptBlock) {
						$x = ''
						if (($_ = $s.IndexOf('::')) -ge 0) {
							$x = $s.Substring(0, $_ + 2)
							$s = $s.Substring($_ + 2)
						}
						$s = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($b.BR[0], $s))
						try {*DP $s $x $b.BR} catch {throw "Parameter 'Extends': $_"}
					}
					continue param
				}}
				elseif ($a -is [System.Management.Automation.ParameterAttribute]) {if ($a.Position -ge 0) {
					$a.Position += 2
				}}
			}
			$_ = New-Object System.Management.Automation.RuntimeDefinedParameter $n, $p.ParameterType, $p.Attributes
			$b.DP[$n] = $_
			${*}.DP[$n] = $_
		}
	}
	${*}.BB.Add($b)
}
*DP $BuildFile '' @()
${*}.DP
}
end {
Remove-Variable Task, File, Result, Safe, Summary
if ($MyInvocation.InvocationName -eq '.') {
	Remove-Variable WhatIf
	return
}

function Enter-Build([Parameter()][scriptblock]$Script) {${*}.B1.EnterBuild = $Script}
function Exit-Build([Parameter()][scriptblock]$Script) {${*}.B1.ExitBuild = $Script}
function Enter-BuildTask([Parameter()][scriptblock]$Script) {${*}.B1.EnterTask = $Script}
function Exit-BuildTask([Parameter()][scriptblock]$Script) {${*}.B1.ExitTask = $Script}
function Enter-BuildJob([Parameter()][scriptblock]$Script) {${*}.B1.EnterJob = $Script}
function Exit-BuildJob([Parameter()][scriptblock]$Script) {${*}.B1.ExitJob = $Script}
function Set-BuildData([Parameter()]$Key, $Value) {${*}.Data[$Key] = $Value}

function Write-Warning([Parameter()]$Message) {
	$PSCmdlet.WriteWarning($Message)
	${*}.Warnings.Add([PSCustomObject]@{Message = $Message; File = $BuildFile; Task = ${*}.Task; InvocationInfo=$MyInvocation})
}

function *Amend($X, $J, $B) {
	$n = $X.Name
	foreach($_ in $J) {
		$r, $s = *Job $_
		if (!($t = ${*}.All[$r])) {*Fin (*Msg "Task '$n': Missing task '$r'." $X) 5}
		$j = $t.Jobs
		$i = $j.Count
		if ($B) {
			for($k = -1; ++$k -lt $i -and $j[$k] -is [string]) {}
			$i = $k
		}
		$j.Insert($i, $(if ($s) {"?$n"} else {$n}))
	}
}

function *At($I) {
	$I.InvocationInfo.PositionMessage.Trim()
}

function *Check($J, $T, $P=@()) {
	foreach($_ in $J) {if ($_ -is [string]) {
		$_ = $_.TrimStart('?')
		if (!($r = ${*}.All[$_])) {
			$_ = "Missing task '$_'."
			*Fin $(if ($T) {*Msg "Task '$($T.Name)': $_" $T} else {"File '$BuildFile': $_"}) 5
		}
		if ($r -in $P) {
			*Fin (*Msg "Task '$($T.Name)': Cyclic reference to '$_'." $T) 5
		}
		*Check $r.Jobs $r ($P + $r)
	}}
}

function *Echo {
	${*c} = $args[0]
	${*t} = "${*c}".Replace("`t", '    ')
	print 3 "exec {$(if (${*t} -match '((?:\r\n|[\r\n]) *)\S') {"$(${*t}.TrimEnd().Replace($matches[1], "`n    "))`n"} else {${*t}})}"
	print 8 "cd $global:pwd"
	foreach(${*v} in ${*c}.Ast.FindAll({$args[0] -is [System.Management.Automation.Language.VariableExpressionAst]}, $true)) {
		${*p} = ${*v}.Parent
		if (${*p} -is [System.Management.Automation.Language.MemberExpressionAst]) {
			if (${*p} -is [System.Management.Automation.Language.InvokeMemberExpressionAst]) {continue}
			${*v} = ${*p}
		}
		if (${*v}.Parent -isnot [System.Management.Automation.Language.AssignmentStatementAst]) {
			${*t} = "${*v}" -replace '^@', '$'
			print 8 "${*t}: $(& ([scriptblock]::Create(${*t})))"
		}
	}
}

function *Err($T) {
	${*}.Errors.Add([PSCustomObject]@{Error = $_; File = $BuildFile; Task = $T})
	print 12 "ERROR: $(if (*My) {$_} else {*Msg $_ $_})"
	if ($T) {$T.Error = $_}
}

function *Fin([Parameter()]$M, $C=0) {
	*Die $M $C
}

function *Help {process{
	[PSCustomObject]@{
		Name = $_.Name
		Synopsis = Get-BuildSynopsis $_
		Jobs = foreach($j in $_.Jobs) {if ($j -is [string]) {$j} else {'{}'}}
	}
}}

function *IO {
	if ((${private:*i} = $Task.Inputs) -is [scriptblock]) {
		*SL
		${*i} = @(& ${*i})
	}
	*SL
	${private:*p} = [System.Collections.Generic.List[object]]@()
	${*i} = foreach($_ in ${*i}) {
		if ($_ -isnot [System.IO.FileInfo]) {$_ = [System.IO.FileInfo](*Path $_)}
		if (!$_.Exists) {*Fin "Missing input '$_'." 13}
		${*p}.Add($_.FullName)
		$_
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
		if (${*p}.Count -ne ${*o}.Count) {*Fin "Different Inputs/Outputs counts: $(${*p}.Count)/$(${*o}.Count)." 6}

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
		if (!${*o}) {*Fin 'Outputs must not be empty.' 5}

		$Task.Inputs = ${*p}
		$m = (${*i} | .{process{$_.LastWriteTime.Ticks}} | Measure-Object -Maximum).Maximum
		foreach($_ in ${*o}) {
			$p = *Path $_
			if (![System.IO.File]::Exists($p)) {return $null, "Missing output '$_'."}
			if ($m -gt [System.IO.File]::GetLastWriteTime($p).Ticks) {return $null, "Out-of-date output '$_'."}
		}
	}
	2, 'Skipping up-to-date output.'
}

function *Job($J) {
	if ($J -is [string]) {if ($J[0] -eq '?') {$J.Substring(1), 1} else {$J}}
	elseif ($J -is [scriptblock]) {$J}
	else {*Fin 'Invalid job.' 5}
}

function *My {
	$_.InvocationInfo.ScriptName -eq $MyInvocation.ScriptName
}

function *Root {
	$t = foreach($_ in ${*}.All.get_Values()) {if ($_.InvocationInfo.ScriptName -eq $BuildFile -and $_.Name -ne '.') {$_}}
	$n = foreach($_ in $t) {$_.Name}
	*Check $n
	$j = foreach($_ in $t) {foreach($_ in $_.Jobs) {if ($_ -is [string]) {$_.TrimStart('?')}}}
	foreach($_ in $n) {if ($_ -notin $j) {$_}}
}

function *Run($_) {if ($_) {
	*SL
	. $_ @args
}}

function *SL($P=$BuildRoot) {
	Set-Location -LiteralPath $P -ErrorAction 1
}

function *Task {
	${private:*p} = "$($args[1])/$($args[0])"
	${private:*n}, ${private:*s} = *Job $args[0]
	New-Variable Task (${*}.Task = ${*}.All[${*n}]) -Option Constant

	if ($Task.Elapsed) {
		print 8 "Done ${*p}"
		return
	}

	$BuildRoot = $Task.B1.BR[0]
	$Task.Started = [DateTime]::Now
	if ((${private:*x} = $Task.If) -is [scriptblock]) {
		*SL
		try {
			${*x} = & ${*x}
		}
		catch {
			*Err $Task
			print 8 (*At $Task)
			${*}.Tasks.Add($Task)
			$Task.Elapsed = [TimeSpan]::Zero
			throw
		}
	}
	if (!${*x}) {
		print 8 "Task ${*p} skipped."
		return
	}

	${private:*i} = , [int]($null -ne $Task.Inputs)
	try {
		. *Run $Task.B1.EnterTask
		foreach($_ in $Task.Jobs) {
			if ($_ -is [string]) {
				try {
					*Task $_ ${*p}
				}
				finally {
					${*}.Task = $Task
				}
				continue
			}
			New-Variable Job $_ -Option ReadOnly -Force
			& ${*}.Header ${*p}

			if (1 -eq ${*i}[0]) {
				try {
					${*i} = *IO
				}
				catch {
					*Err $Task
					throw
				}
				print 8 ${*i}[1]
			}
			if (${*i}[0]) {
				continue
			}

			try {
				. *Run $Task.B1.EnterJob
				*SL
				if (0 -eq ${*i}[0]) {
					& $Job
				}
				else {
					$Inputs = $Task.Inputs
					$Outputs = $Task.Outputs
					if ($Task.Partial) {
						${*x} = 0
						$Inputs | .{process{
							$2 = $Outputs[${*x}++]
							$_
						}} | & $Job
					}
					else {
						$Inputs | & $Job
					}
				}
			}
			catch {
				*Err $Task
				print 8 (*At $Task)
				throw
			}
			finally {
				. *Run $Task.B1.ExitJob
			}
		}
	}
	catch {
		$Task.Error = $_
		if (!${*s} -or (*Unsafe ${*n} $BuildTask)) {throw}
	}
	finally {
		$Task.Elapsed = [DateTime]::Now - $Task.Started
		${*}.Tasks.Add($Task)
		if (!$Task.Error) {
			if (${*}.XCheck) {& ${*}.XCheck}
			& ${*}.Footer ${*p}
		}
		*Run $Task.Done
		. *Run $Task.B1.ExitTask
	}
}

function *Unsafe($N, $J) {
	if ($N -in $J) {return 1}
	foreach($_ in $J) {if ($_ -is [string]) {
		$_ = $_.TrimStart('?')
		if ($_ -ne $N -and ($t = ${*}.All[$_]) -and $t.If -and (*Unsafe $N $t.Jobs)) {return 1}
	}}
}

function *What {
	& $PSScriptRoot/Show-TaskHelp.ps1
}

$ErrorActionPreference = 1
if (${*}.Q = $BuildTask -eq '?' -or $BuildTask -eq '??') {
	$WhatIf = $true
}

${*}.Error = $null
try {
	if ($BuildTask -eq '**') {
		${*}.A = 0
		foreach($_ in $BuildFile) {
			Invoke-Build * $_.FullName -Safe:${*}.Safe
		}
		${*}.B = 1
		exit
	}

	### load
	New-Variable Task @{Name = $BuildFile} -Option Constant
	${*p} = @(foreach($_ in ${*}.DP.get_Values()) {if ($_.IsSet) {$_}})
	${private:**} = @(
		foreach(${private:*b} in ${*}.BB) {
			${*}.B1 = ${*b}
			${private:*s} = @{}
			foreach($_ in ${*p}) {
				if (${*b}.DP.ContainsKey($_.Name)) {
					${*s}[$_.Name] = $_.Value
				}
			}
			$BuildRoots = @(${*b}.BR)
			$BuildRoot = $BuildRoots[0]
			*SL
			$_ = ${*s}
			. ${*b}.FS @_
			if (![System.IO.Directory]::Exists(($_ = *Path $BuildRoot))) {*Fin "Missing build root '$BuildRoot'." 13}
			${*b}.BR[0] = $_
		}
	)
	Remove-Variable BuildRoots
	foreach($_ in ${**}) {
		Write-Warning "Unexpected output: $_."
		if ($_ -is [scriptblock]) {*Fin "Dangling scriptblock at $($_.File):$($_.StartPosition.StartLine)" 6}
	}
	if (!(${**} = ${*}.All).get_Count()) {*Fin "No tasks in '$BuildFile'." 6}

	foreach($_ in ${**}.get_Values()) {
		if ($_.Before) {*Amend $_ $_.Before 1}
	}
	foreach($_ in ${**}.get_Values()) {
		if ($_.After) {*Amend $_ $_.After}
	}

	if (${*}.Q) {
		*Check ${**}.get_Keys()
		if ($BuildTask -eq '?') {
			${**}.get_Values() | *Help
		}
		else {
			${**}
		}
		exit
	}

	if ($BuildTask -eq '*') {
		$BuildTask = *Root
	}
	else {
		if (!$BuildTask -or '.' -eq $BuildTask) {
			$BuildTask = if (${**}['.']) {'.'} else {${**}.Item(0).Name}
		}
		*Check $BuildTask
	}
	if ($WhatIf) {
		*What
		exit
	}

	print 11 "Build $($BuildTask -join ', ') $BuildFile"
	foreach($_ in ${*}.Redefined) {
		if (($_ = $_.Name) -ne '.') {print 8 "Redefined task '$_'."}
	}
	foreach($_ in ${*}.Doubles) {
		if (${*}.All[$_[1]].If -isnot [scriptblock]) {
			Write-Warning "Task '$($_[0])' always skips '$($_[1])'."
		}
	}

	### build
	${*}.A = 0
	try {
		foreach($_ in ${*}.BB) {
			$BuildRoot = $_.BR[0]
			. *Run $_.EnterBuild
		}
		if (${*}.XBuild) {. ${*}.XBuild}
		if (${*}.XCheck) {& ${*}.XCheck}
		foreach($_ in $BuildTask) {
			*Task $_ ''
		}
	}
	finally {
		${*}.Task = $null
		for($$ = ${*}.BB.Count; --$$ -ge 0) {
			$BuildRoot = ${*}.BB[$$].BR[0]
			. *Run ${*}.BB[$$].ExitBuild
		}
	}
	${*}.B = 1
	exit
}
catch {
	${*}.B = 2
	${*}.Error = $_
	if (!${*}.Errors) {*Err}
	if ($_.FullyQualifiedErrorId -eq 'PositionalParameterNotFound,Add-BuildTask') {
		Write-Warning 'Check task parameters: Name and comma separated Jobs.'
	}
	if (${*}.Safe) {
		exit
	}
	elseif (*My) {
		$PSCmdlet.ThrowTerminatingError($_)
	}
	throw
}
finally {
	*SL ${*}.CD
	if (${*}.B -and !${*}.Q) {
		$t = ${*}.Tasks
		$e = ${*}.Errors
		if (${*}.Summary) {
			print 11 'Build summary:'
			foreach($_ in $t) {
				'{0,-16} {1} - {2}:{3}' -f $_.Elapsed, $_.Name, $_.InvocationInfo.ScriptName, $_.InvocationInfo.ScriptLineNumber
				if ($_ = $_.Error) {
					print 12 "ERROR: $(if (*My) {$_} else {*Msg $_ $_})"
				}
			}
		}
		if ($w = ${*}.Warnings) {
			foreach($_ in $w) {
				"WARNING: $(if ($_.Task) {"/$($_.Task.Name) "})$($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)"
				print 14 $_.Message
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
		print $c "$m. $($t.Count) tasks, $($e.Count) errors, $($w.Count) warnings $((${*}.Elapsed = [DateTime]::Now - ${*}.Started))"
	}
}
}
