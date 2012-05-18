
<#
Invoke-Build - Build Automation in PowerShell
Copyright (c) 2011-2012 Roman Kuzmin

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

#.ExternalHelp Invoke-Build.ps1-Help.xml
param
(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][hashtable]$Parameters,
	[hashtable]$Hook,
	$Result,
	[switch]$Safe,
	[switch]$WhatIf
)

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildVersion
{[System.Version]'1.3.0'}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Add-BuildTask
{
	[CmdletBinding(DefaultParameterSetName='.')]
	param
	(
		[Parameter(Position=0, Mandatory=$true)][string]$Name,
		[Parameter(Position=1)][object[]]$Jobs,
		$If = $true,
		[object[]]$After,
		[object[]]$Before,
		[Parameter(ParameterSetName='Incremental')][hashtable]$Incremental,
		[Parameter(ParameterSetName='Partial')][hashtable]$Partial
	)
	try {
		$it = $BuildList[$Name]
		if ($it) {throw *Fix* 'Task name already exists:' $it}

		$it = Select-Object Name, Error, Started, Elapsed, Jobs, Try, If, Inputs, Outputs, Partial, After, Before, InvocationInfo -InputObject 1
		$it.Name = $Name
		$it.Jobs = $jobList = [System.Collections.ArrayList]@()
		$it.Try = $tryList = [System.Collections.ArrayList]@()
		$it.If = $If
		$it.After = $After
		$it.Before = $Before
		$it.InvocationInfo = $MyInvocation
		$BuildList.Add($Name, $it)

		switch($PSCmdlet.ParameterSetName) {
			'Incremental' {
				$it.Inputs, $it.Outputs = *KV* $Incremental
			}
			'Partial' {
				$it.Inputs, $it.Outputs = *KV* $Partial
				$it.Partial = $true
			}
		}

		if ($Jobs) { foreach($_ in $Jobs) { foreach($_ in $_) {
			$ref, $data = *Ref* $_
			if ($data) {
				$null = $jobList.Add($ref)
				if (1 -eq $data) {
					$null = $tryList.Add($ref)
				}
			}
			elseif ($_ -is [string] -or $_ -is [scriptblock]) {
				$null = $jobList.Add($_)
			}
			else {throw "Invalid job type."}
		}}}
	}
	catch {*Die* "Task '$Name': $_" InvalidArgument}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildError([Parameter(Mandatory=$true)][string]$Task)
{
	$_ = $BuildList[$Task]
	if (!$_) {*Die* "Task '$Task' is not defined." ObjectNotFound}
	$_.Error
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildProperty([Parameter(Mandatory=$true)][string]$Name, $Value)
{
	$_ = $PSCmdlet.GetVariableValue($Name)
	if ($null -eq $_) {
		$_ = [System.Environment]::GetEnvironmentVariable($Name)
		if ($null -eq $_) {
			if ($null -eq $Value) {*Die* "PowerShell or environment variable '$Name' is not defined." ObjectNotFound}
			$_ = $Value
		}
	}
	$_
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Assert-BuildTrue([Parameter()]$Condition, [string]$Message)
{
	if (!$Condition) {*Die* $(if ($Message) {"Assertion failed: $Message"} else {'Assertion failed.'}) InvalidOperation}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Invoke-BuildExec([Parameter(Mandatory=$true)][scriptblock]$Command, [int[]]$ExitCode = 0)
{
	${private:-Command} = $Command
	${private:-ExitCode} = $ExitCode
	Remove-Variable Command, ExitCode
	. ${-Command}
	if (${-ExitCode} -notcontains $LastExitCode) {*Die* "The command {${-Command}} exited with code $LastExitCode." InvalidResult}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Use-BuildAlias([Parameter()][string]$Path, [Parameter(Mandatory=$true)][string[]]$Name)
{
	if ($Path) {
		try {
			$dir = if ($Path.StartsWith('Framework', [System.StringComparison]::OrdinalIgnoreCase)) {
				"$env:windir\Microsoft.NET\$Path"
			}
			else {
				$PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
			}
			if (![System.IO.Directory]::Exists($dir)) {throw "Directory does not exist: '$dir'."}
		}
		catch {*Die* $_ InvalidArgument}
	}
	else {
		$dir = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
	}

	foreach($_ in $Name) {
		Set-Alias $_ (Join-Path $dir $_) -Scope 1
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Write-BuildText([System.ConsoleColor]$Color, [string]$Text)
{
	$saved = $Host.UI.RawUI.ForegroundColor
	try {
		$Host.UI.RawUI.ForegroundColor = $Color
		$Text
	}
	finally {
		$Host.UI.RawUI.ForegroundColor = $saved
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildFile($Path)
{
	$files = [System.IO.Directory]::GetFiles($Path, '*.build.ps1')
	if ($files.Count -eq 1) {
		$files
	}
	else {
		foreach($_ in $files) { if ([System.IO.Path]::GetFileName($_) -eq '.build.ps1') {return $_} }
	}
}

if ($MyInvocation.InvocationName -eq '.') {
	"Invoke-Build.ps1 Version $(Get-BuildVersion)`r`nCopyright (c) 2011-2012 Roman Kuzmin"
	'Add-BuildTask', 'Use-BuildAlias', 'Invoke-BuildExec', 'Assert-BuildTrue', 'Get-BuildProperty', 'Get-BuildError', 'Get-BuildVersion','Write-BuildText' |
	.{process{ Get-Help $_}} | Format-Table Name, Synopsis -AutoSize | Out-String
	return
}

if ($Host.Name -eq 'Default Host' -or $Host.Name -eq 'ServerRemoteHost' -or !$Host.UI -or !$Host.UI.RawUI) {
	function Write-BuildText([System.ConsoleColor]$Color, [string]$Text) {$Text}
}

function Write-Warning([string]$Message)
{
	$_ = "WARNING: " + $Message
	Write-BuildText Yellow $_
	++$BuildInfo.WarningCount
	++$BuildInfo.AllWarningCount
	$null = $BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
}

function *Die*([string]$Message, [System.Management.Automation.ErrorCategory]$Category = 0)
{$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]$Message), $null, $Category, $null))}

function *My*
{$_.InvocationInfo.ScriptName -like '*\Invoke-Build.ps1'}

function *II*($_)
{$_ = $_.InvocationInfo.PositionMessage; if ($_.StartsWith("`n")) {$_.Trim().Replace("`n", "`r`n")} else {$_}}

function *Fix*($Text, $II)
{"$Text`r`n$(*II* $II)"}

function *KV*($_)
{
	if ($_.Count -ne 1) {throw "Invalid pair, expected hashtable @{X = Y}."}
	$_.Keys
	$_.Values
}

function *Ref*($_)
{if ($_ -is [hashtable]) {*KV* $_} else {$_}}

function *Alter*($Add, $Tasks, [switch]$After)
{
	foreach($_ in $Tasks) {
		$ref, $data = *Ref* $_
		$it = $BuildList[$ref]
		if (!$it) {throw "Task '$ref' is not defined."}

		$jobs = $it.Jobs
		$i = $jobs.Count
		if ($After) {
			for($1 = $i - 1; $1 -ge 0; --$1) {
				if ($jobs[$1] -is [scriptblock]) {
					$i = $1 + 1
					break
				}
			}
		}
		else {
			for($1 = 0; $1 -lt $i; ++$1) {
				if ($jobs[$1] -is [scriptblock]) {
					$i = $1
					break
				}
			}
		}

		$jobs.Insert($i, $Add)
		if (1 -eq $data) {
			$null = $it.Try.Add($Add)
		}
	}
}

function *IO*($Task)
{
	${private:-it} = $Task
	Remove-Variable Task

	${private:-in} = ${-it}.Inputs
	if (${-in} -is [scriptblock]) {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		${-in} = @(& ${-in})
	}

	${private:-paths} = [System.Collections.ArrayList]@()
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	${-in} = foreach(${private:-} in ${-in}) {
		if (${-} -isnot [System.IO.FileInfo]) {
			${-} = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath(${-})
			if (!${-}.Exists) {throw "Input file does not exist: '${-}'."}
		}
		$null = ${-paths}.Add(${-}.FullName)
		${-}
	}

	if (!${-paths}) {
		'Skipping because there is no input.'
		return
	}

	if (${-it}.Partial) {
		${private:-out} = @(if (${-it}.Outputs -is [scriptblock]) {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${-paths} | & ${-it}.Outputs
		}
		else {
			${-it}.Outputs
		})
		if (${-paths}.Count -ne ${-out}.Count) {throw "Different input and output counts: $(${-paths}.Count) and $(${-out}.Count)."}

		$1 = -1
		$in2 = [System.Collections.ArrayList]@()
		$out2 = [System.Collections.ArrayList]@()
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${-in}) {
			++$1
			$path = ${-out}[$1]
			$file = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($path)
			if (!$file.Exists -or $_.LastWriteTime -gt $file.LastWriteTime) {
				$null = $in2.Add(${-paths}[$1]), $out2.Add($path)
			}
		}

		if ($in2) {
			${-it}.Inputs = $in2
			${-it}.Outputs = $out2
			return
		}
	}
	else {
		${-it}.Inputs = ${-paths}

		if (${-it}.Outputs -is [scriptblock]) {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${-it}.Outputs = & ${-it}.Outputs
			if (!${-it}.Outputs) {throw 'Incremental output cannot be empty.'}
		}

		$max = (${-in} | .{process{ $_.LastWriteTime.Ticks }} | Measure-Object -Maximum).Maximum
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${-it}.Outputs) {
			$_ = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)
			if (!$_.Exists -or $_.LastWriteTime.Ticks -lt $max) {return}
		}
	}
	'Skipping because all outputs are up-to-date with respect to the inputs.'
}

function *Task*($Name, $Path)
{
	${private:-it} = $BuildList[$Name]
	${private:-path} = if ($Path) {"$Path/$(${-it}.Name)"} else {${-it}.Name}
	if (${-it}.Error) {
		Write-BuildText DarkGray "${-path} failed."
		return
	}
	if (${-it}.Started) {
		Write-BuildText DarkGray "Done ${-path}"
		return
	}
	Remove-Variable Name, Path

	${private:-if} = ${-it}.If
	if (${-if} -is [scriptblock]) {
		try {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${-if} = & ${-if}
		}
		catch {
			${-it}.Error = $_
			throw
		}
	}
	if (!${-if}) {
		Write-BuildText DarkGray "${-path} skipped."
		return
	}

	${-it}.Started = [System.DateTime]::Now
	${private:-n} = 0
	${private:-count} = ${-it}.Jobs.Count
	${private:-io} = $null -ne ${-it}.Inputs
	${private:-skip} = $false
	try {
		foreach(${private:-job} in ${-it}.Jobs) {
			++${-n}
			if (${-job} -is [string]) {
				try {
					*Task* ${-job} ${-path}
				}
				catch {
					if (${-it}.Try -notcontains ${-job}) {throw}
					foreach($it in $BuildTask) {
						$why = *Try-Task* $it ${-job}
						if ($why) {
							Write-BuildText Red $why
							throw
						}
					}
					Write-BuildText Red (*Fix* "ERROR: $_" $_)
				}
			}
			else {
				${private:-log} = "${-path} (${-n}/${-count})"
				Write-BuildText DarkYellow "${-log}:"

				if ($WhatIf) {
					${-job}
					continue
				}

				if (${-io}) {
					${-io} = $false
					${-skip} = *IO* ${-it}
				}

				if (${-skip}) {
					Write-BuildText DarkYellow ${-skip}
					continue
				}

				Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
				if ($null -eq ${-skip}) {
					$Inputs = ${-it}.Inputs
					$Outputs = ${-it}.Outputs
					if (${-it}.Partial) {
						${private:-} = 0
						$Inputs | .{process{
							$2 = $Outputs[${-}]
							++${-}
							$_
						}} | & ${-job}
					}
					else {
						$Inputs | & ${-job}
					}
				}
				else {
					& ${-job}
				}

				if (${-it}.Jobs.Count -ge 2) {
					Write-BuildText DarkYellow "Done ${-log}"
				}
			}
		}

		$_ = [System.DateTime]::Now - ${-it}.Started
		${-it}.Elapsed = $_
		Write-BuildText DarkYellow "Done ${-path} $_"
	}
	catch {
		${-it}.Elapsed = [System.DateTime]::Now - ${-it}.Started
		${-it}.Error = $_
		++$BuildInfo.ErrorCount
		++$BuildInfo.AllErrorCount
		$_ = if (*My*) {"ERROR: Task '${-path}': $_"} else {*Fix* "ERROR: Task '${-path}': $_" $_}
		$null = $BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
		Write-BuildText Yellow (*II* ${-it})
		throw
	}
	finally {
		$null = $BuildInfo.Tasks.Add(${-it}), $BuildInfo.AllTasks.Add(${-it})
	}
}

function *Try-Task*($Try, $Task)
{
	$it = $BuildList[$Try]
	if (!$it.If) {return}

	if ($it.Jobs -contains $Task) {
		if ($it.Try -notcontains $Task) {
			"Task '$Try' calls failed '$Task' not protected."
		}
		return
	}

	foreach($_ in $it.Jobs) { if ($_ -is [string]) {
		$why = *Try-Task* $_ $Task
		if ($why) {return $why}
	}}
}

function *Hook*
{
	if ($BuildHook) {
		${private:-} = $BuildHook[$args[0]]
		if (${-}) {& ${-}}
	}
}

function *Test-Task*($Task) {
	foreach($_ in $Task) {
		$it = $BuildList[$_]
		if (!$it) {throw "Task '$_' is not defined."}
		*Test-Tree* $it ([System.Collections.ArrayList]@())
	}
}

function *Test-Tree*($Task, $Done)
{
	$n = 1 + $Done.Add($Task)
	foreach($_ in $Task.Jobs) { if ($_ -is [string]) {
		$it = $BuildList[$_]
		if (!$it) {throw *Fix* "Task '$($Task.Name)': Task '$_' is not defined." $Task}
		if ($Done.Contains($it)) {throw *Fix* "Task '$($Task.Name)': Cyclic reference to '$_'." $Task}
		*Test-Tree* $it $Done
		$Done.RemoveRange($n, $Done.Count - $n)
	}}
}

function *Summary*($Done, $Tasks, $Errors, $Warnings, $Span)
{
	$color, $text = if ($Done -eq 2) {'Red', 'Build FAILED'}
	elseif ($Errors) {'Red', 'Build completed with errors'}
	elseif ($Warnings) {'Yellow', 'Build succeeded with warnings'}
	else {'Green', 'Build succeeded'}
	Write-BuildText $color "$text. $Tasks tasks, $Errors errors, $Warnings warnings, $Span"
}

$ErrorActionPreference = 'Stop'
${private:-location} = $PSCmdlet.GetUnresolvedProviderPathFromPSPath('')
try {
	if ($File) {
		$BuildFile = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($File)
		if (!([System.IO.File]::Exists($BuildFile))) {throw "Build file does not exist: '$BuildFile'."}
	}
	else {
		$BuildFile = Get-BuildFile ${-location}
		if (!$BuildFile) {
			$BuildFile = *Hook* GetFile
			if (!$BuildFile) {throw "Default build file is not found."}
		}
	}
	$BuildRoot = Split-Path $BuildFile
}
catch {*Die* "$_" ObjectNotFound}

${private:-up} = $PSCmdlet.SessionState.PSVariable.Get('BuildInfo')
if (${-up}) {
	${-up} = if (${-up}.Description -eq 'Invoke-Build') {${-up}.Value}
}
Set-Alias assert Assert-BuildTrue
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias
Set-Alias Invoke-Build $MyInvocation.MyCommand.Path
Set-Alias Invoke-Builds (Join-Path (Split-Path $MyInvocation.MyCommand.Path) 'Invoke-Builds.ps1')
New-Variable -Name BuildList -Option Constant -Value ([System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase))
New-Variable -Name BuildInfo -Option Constant -Description Invoke-Build -Value `
(Select-Object AllTasks, AllMessages, AllErrorCount, AllWarningCount, Tasks, Messages, ErrorCount, WarningCount, Started, Elapsed, Error -InputObject 1)
$BuildInfo.AllTasks = [System.Collections.ArrayList]@()
$BuildInfo.AllMessages = [System.Collections.ArrayList]@()
$BuildInfo.AllErrorCount = 0
$BuildInfo.AllWarningCount = 0
$BuildInfo.Tasks = [System.Collections.ArrayList]@()
$BuildInfo.Messages = [System.Collections.ArrayList]@()
$BuildInfo.ErrorCount = 0
$BuildInfo.WarningCount = 0
$BuildInfo.Started = [System.DateTime]::Now
if ('?' -eq $Task) {$WhatIf = $true}
if ($Result) {
	$_ = if ('?' -eq $Task) {$BuildList} else {$BuildInfo}
	if ($Result -is [string]) {New-Variable -Force -Scope 1 $Result $_}
	else {$Result.Value = $_}
}
$BuildTask = $Task
$BuildHook = $Hook
${private:-Result} = $Result
${private:-Safe} = $Safe
$_ = $Parameters
Remove-Variable Task, File, Parameters, Result, Safe, Hook

${private:-done} = 0
try {
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') $BuildFile"
	$_ = if ($_) {. $BuildFile @_} else {. $BuildFile}
	if (!$BuildList.Count) {throw "There is no task in '$BuildFile'."}
	$_
	foreach($_ in $_) { if ($_ -is [scriptblock]) {throw "Invalid build script syntax at the script block {$_}"} }

	foreach(${private:-it} in $BuildList.Values) {
		try {
			if (${-it}.Before) {*Alter* ${-it}.Name ${-it}.Before}
			if (${-it}.After) {*Alter* ${-it}.Name ${-it}.After -After}
		}
		catch {throw *Fix* "Task '$(${-it}.Name)': $_" ${-it}}
	}

	if ('?' -eq $BuildTask) {
		*Test-Task* $BuildList.Keys
		if (!${-Result}) {
			foreach($_ in $BuildList.Values) {@"
$($_.Name) $(($_.Jobs | %{ if ($_ -is [string]) {$_} else {'{..}'} }) -join ', ') $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)
"@}
		}
		return
	}

	if ('*' -eq $BuildTask) {
		*Test-Task* $BuildList.Keys
		$BuildTask = foreach($_ in $BuildList.Keys) {
			foreach(${private:-it} in $BuildList.Values) {
				if (${-it}.Jobs -contains $_) {
					$_ = $null
					break
				}
			}
			if ($_) {$_}
		}
	}
	else {
		if (!$BuildTask -or '.' -eq $BuildTask) {
			$BuildTask = if ($BuildList.Contains('.')) {'.'} else {$BuildList.Item(0).Name}
		}
		*Test-Task* $BuildTask
	}

	foreach($_ in $BuildTask) {
		*Task* $_
	}
	${-done} = 1
}
catch {
	${-done} = 2
	$BuildInfo.Error = $_
	if (!${-Safe}) {if (*My*) {$PSCmdlet.ThrowTerminatingError($_)} else {throw}}
}
finally {
	Set-Location -LiteralPath ${-location} -ErrorAction Stop
	if (${-done}) {
		$BuildInfo.Elapsed = [System.DateTime]::Now - $BuildInfo.Started
		$BuildInfo.Messages
		*Summary* ${-done} $BuildInfo.Tasks.Count $BuildInfo.ErrorCount $BuildInfo.WarningCount $BuildInfo.Elapsed

		if (${-up}) {
			${-up}.AllTasks.AddRange($BuildInfo.AllTasks)
			${-up}.AllMessages.AddRange($BuildInfo.AllMessages)
			${-up}.AllErrorCount += $BuildInfo.AllErrorCount
			${-up}.AllWarningCount += $BuildInfo.AllWarningCount
		}
		elseif ($BuildInfo.AllTasks.Count -ne $BuildInfo.Tasks.Count) {
			$BuildInfo.AllMessages
			*Summary* ${-done} $BuildInfo.AllTasks.Count $BuildInfo.AllErrorCount $BuildInfo.AllWarningCount $BuildInfo.Elapsed
		}
	}
}
