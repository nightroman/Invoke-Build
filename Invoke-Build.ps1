
<#
Invoke-Build.ps1 - Build Automation in PowerShell
Copyright (c) 2011 Roman Kuzmin

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
	[Parameter(Position = 0)][string[]]$Task,
	[Parameter(Position = 1)][string]$File,
	[Parameter(Position = 2)][hashtable]$Parameters,
	[Parameter()][hashtable]$Hook,
	[Parameter()][string]$Result,
	[Parameter()][switch]$WhatIf
)

### Aliases
Set-Alias assert Assert-BuildTrue
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildVersion
{
	[System.Version]'1.1.0'
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Add-BuildTask
{
	[CmdletBinding(DefaultParameterSetName='.')]
	param
	(
		[Parameter(Position = 0, Mandatory = $true)][string]$Name,
		[Parameter(Position = 1)][object[]]$Jobs,
		[Parameter()][object]$If = $true,
		[Parameter(ParameterSetName = 'Incremental')][hashtable]$Incremental,
		[Parameter(ParameterSetName = 'Partial')][hashtable]$Partial,
		[Parameter()][object[]]$After,
		[Parameter()][object[]]$Before
	)
	try {
		$task = $BuildList[$Name]
		if ($task) {
			throw "Task name already exists:`r`n$(*Fix* $task)"
		}

		$jobList = [System.Collections.ArrayList]@()
		$tryList = [System.Collections.ArrayList]@()

		$task = Select-Object Name, Error, Started, Elapsed, Jobs, Try, If, Inputs, Outputs, Partial, After, Before, Info -InputObject 1
		$task.Name = $Name
		$task.Jobs = $jobList
		$task.Try = $tryList
		$task.If = $If
		$task.After = $After
		$task.Before = $Before
		$task.Info = $MyInvocation

		switch($PSCmdlet.ParameterSetName) {
			'Incremental' {
				$task.Inputs, $task.Outputs = *KV* $Incremental
			}
			'Partial' {
				$task.Inputs, $task.Outputs = *KV* $Partial
				$task.Partial = $true
			}
		}

		if ($Jobs) { foreach($_ in $Jobs) { foreach($_ in $_) {
			$name2, $data = *Ref* $_
			if ($data) {
				$null = $jobList.Add($name2)
				if (1 -eq $data) {
					$null = $tryList.Add($name2)
				}
			}
			elseif (($_ -is [string]) -or ($_ -is [scriptblock])) {
				$null = $jobList.Add($_)
			}
			else {
				throw "Invalid job type."
			}
		}}}

		$BuildList.Add($Name, $task)
	}
	catch {
		*Die* "Task '$Name': $_" InvalidArgument
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildError
(
	[Parameter(Mandatory = $true)][string]$Task
)
{
	$_ = $BuildList[$Task]
	if (!$_) {
		*Die* "Task '$Task' is not defined." ObjectNotFound $Task
	}
	$_.Error
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildProperty
(
	[Parameter(Mandatory = $true)][string]$Name,
	[Parameter()]$Value
)
{
	$_ = $PSCmdlet.GetVariableValue($Name)
	if ($null -eq $_) {
		$_ = [System.Environment]::GetEnvironmentVariable($Name)
		if ($null -eq $_) {
			if ($null -eq $Value) {
				*Die* "PowerShell or environment variable '$Name' is not defined." ObjectNotFound $Name
			}
			$_ = $Value
		}
	}
	$_
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Assert-BuildTrue
(
	[Parameter()]$Condition,
	[Parameter()][string]$Message
)
{
	if (!$Condition) {
		if ($Message) {
			*Die* "Assertion failed: $Message" InvalidOperation
		}
		else {
			*Die* 'Assertion failed.' InvalidOperation
		}
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Invoke-BuildExec
(
	[Parameter(Mandatory = $true)][scriptblock]$Command,
	[Parameter()][int[]]$ExitCode = 0
)
{
	${private:-Command} = $Command
	${private:-ExitCode} = $ExitCode
	Remove-Variable Command, ExitCode

	. ${private:-Command}

	if (${private:-ExitCode} -notcontains $LastExitCode) {
		*Die* "The command {${private:-Command}} exited with code $LastExitCode." InvalidResult $LastExitCode
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Use-BuildAlias
(
	[Parameter()][string]$Path,
	[Parameter(Mandatory = $true)][string[]]$Name
)
{
	if ($Path) {
		try {
			if ($Path.StartsWith('Framework', [System.StringComparison]::OrdinalIgnoreCase)) {
				$dir = "$env:windir\Microsoft.NET\$Path"
			}
			else {
				$dir = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
			}
			if (![System.IO.Directory]::Exists($dir)) {
				throw "Directory does not exist: '$dir'."
			}
		}
		catch {
			*Die* $_ InvalidArgument $Path
		}
	}
	else {
		$dir = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
	}

	foreach($_ in $Name) {
		Set-Alias $_ (Join-Path $dir $_) -Scope 1
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Write-BuildText
(
	[System.ConsoleColor]$Color,
	[string]$Text
)
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
		foreach($_ in $files) { if ([System.IO.Path]::GetFileName($_) -eq '.build.ps1') { return $_ } }
	}
}

### Dot-sourced.
if ($PSCmdlet.MyInvocation.InvocationName -eq '.') {
	@"
Invoke-Build.ps1 Version $(Get-BuildVersion)
Copyright (c) 2011 Roman Kuzmin
"@
	'task', 'use', 'exec', 'assert', 'property', 'error', 'Get-BuildVersion','Write-BuildText' |
	%{ Get-Help $_ } | Format-Table Name, Synopsis -AutoSize | Out-String
	return
}

if ($Host.Name -eq 'Default Host' -or !$Host.UI -or !$Host.UI.RawUI) {
	function Write-BuildText([System.ConsoleColor]$Color, [string]$Text) { $Text }
}

function Write-Warning([string]$Message)
{
	$_ = "WARNING: " + $Message
	Write-BuildText Yellow $_
	++$BuildInfo.WarningCount
	++$BuildInfo.AllWarningCount
	$null = $BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
}

function *Die*([string]$Message, [System.Management.Automation.ErrorCategory]$Category = 0, $Target)
{
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]$Message), $null, $Category, $Target))
}

function *Alter*($Extra, $Tasks, [switch]$After)
{
	foreach($_ in $Tasks) {
		$name, $data = *Ref* $_
		$task = $BuildList[$name]
		if (!$task) {
			throw "Task '$name' is not defined."
		}

		$jobs = $task.Jobs
		$index = $jobs.Count
		if ($After) {
			for($$ = $index - 1; $$ -ge 0; --$$) {
				if ($jobs[$$] -is [scriptblock]) {
					$index = $$ + 1
					break
				}
			}
		}
		else {
			for($$ = 0; $$ -lt $index; ++$$) {
				if ($jobs[$$] -is [scriptblock]) {
					$index = $$
					break
				}
			}
		}

		$jobs.Insert($index, $Extra)
		if (1 -eq $data) {
			$null = $task.Try.Add($Extra)
		}
	}
}

function *KV*($Hash)
{
	if ($Hash.Count -ne 1) {
		throw "Invalid pair, expected hashtable @{X = Y}."
	}
	, @($Hash.Keys)[0]
	, @($Hash.Values)[0]
}

function *Ref*($Ref)
{
	if ($Ref -is [hashtable]) {
		*KV* $Ref
	}
	else {
		$Ref
	}
}

function *Fix*($Task)
{
	$Task.Info.PositionMessage.Trim().Replace("`n", "`r`n")
}

function *IO*($Task)
{
	${private:-Task} = $Task
	Remove-Variable Task

	${private:-inputs} = ${private:-Task}.Inputs
	if (${private:-inputs} -is [scriptblock]) {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		${private:-inputs} = @(& ${private:-inputs})
	}

	${private:-paths} = [System.Collections.ArrayList]@()
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	${private:-inputs} = foreach(${private:-in} in ${private:-inputs}) {
		if (${private:-in} -isnot [System.IO.FileInfo]) {
			${private:-in} = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath(${private:-in})
			if (!${private:-in}.Exists) {
				throw "Input file does not exist: '${private:-in}'."
			}
		}
		$null = ${private:-paths}.Add(${private:-in}.FullName)
		${private:-in}
	}

	if (!${private:-paths}) {
		'Skipping because there is no input.'
		return
	}

	if (${private:-Task}.Partial) {
		if (${private:-Task}.Outputs -is [scriptblock]) {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${private:-outputs} = @(${private:-paths} | & ${private:-Task}.Outputs)
		}
		else {
			${private:-outputs} = @(${private:-Task}.Outputs)
		}
		if (${private:-paths}.Count -ne ${private:-outputs}.Count) {
			throw "Different input and output counts: $(${private:-paths}.Count) and $(${private:-outputs}.Count)."
		}

		$index = -1
		$inputs2 = [System.Collections.ArrayList]@()
		$outputs2 = [System.Collections.ArrayList]@()
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${private:-inputs}) {
			++$index
			$path = ${private:-outputs}[$index]
			$file = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($path)
			if (!$file.Exists -or ($_.LastWriteTime -gt $file.LastWriteTime)) {
				$null = $inputs2.Add(${private:-paths}[$index]), $outputs2.Add($path)
			}
		}

		if ($inputs2) {
			${private:-Task}.Inputs = $inputs2
			${private:-Task}.Outputs = $outputs2
			return
		}
	}
	else {
		${private:-Task}.Inputs = ${private:-paths}

		if (${private:-Task}.Outputs -is [scriptblock]) {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${private:-Task}.Outputs = & ${private:-Task}.Outputs
			if (!${private:-Task}.Outputs) {
				throw 'Incremental output cannot be empty.'
			}
		}

		$ticks = (${private:-inputs} | .{process{ $_.LastWriteTime.Ticks }} | Measure-Object -Maximum).Maximum
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${private:-Task}.Outputs) {
			$_ = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)
			if (!$_.Exists -or $_.LastWriteTime.Ticks -lt $ticks) {
				return
			}
		}
	}
	'Skipping because all outputs are up-to-date with respect to the inputs.'
}

function *Task*($Name, $Path)
{
	${private:-task} = $BuildList[$Name]
	${private:-path} = if ($Path) { "$Path/$(${private:-task}.Name)" } else { ${private:-task}.Name }
	if (${private:-task}.Error) {
		Write-BuildText DarkGray "${private:-path} failed."
		return
	}
	if (${private:-task}.Started) {
		Write-BuildText DarkGray "${private:-path} is done."
		return
	}
	Remove-Variable Name, Path

	${private:-if} = ${private:-task}.If
	if (${private:-if} -is [scriptblock]) {
		try {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${private:-if} = & ${private:-if}
		}
		catch {
			${private:-task}.Error = $_
			throw
		}
	}
	if (!${private:-if}) {
		Write-BuildText DarkGray "${private:-path} skipped."
		return
	}

	${private:-task}.Started = [System.DateTime]::Now
	${private:-count} = ${private:-task}.Jobs.Count
	${private:-number} = 0
	${private:-io} = $null -ne ${private:-task}.Inputs
	${private:-skip} = $false
	try {
		foreach(${private:-job} in ${private:-task}.Jobs) {
			++${private:-number}
			if (${private:-job} -is [string]) {
				try {
					*Task* ${private:-job} ${private:-path}
				}
				catch {
					if (${private:-task}.Try -notcontains ${private:-job}) {
						throw
					}
					foreach($it in $BuildTask) {
						$why = *Try-Task* $it ${private:-job}
						if ($why) {
							Write-BuildText Red $why
							throw
						}
					}
					Write-BuildText Red ($_ | Out-String)
				}
			}
			else {
				${private:-title} = "${private:-path} (${private:-number}/${private:-count})"
				Write-BuildText DarkYellow "${private:-title}:"

				if ($WhatIf) {
					${private:-job}
					continue
				}

				if (${private:-io}) {
					${private:-io} = $false
					${private:-skip} = *IO* ${private:-task}
				}

				if (${private:-skip}) {
					Write-BuildText DarkYellow ${private:-skip}
					continue
				}

				Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
				if ($null -eq ${private:-skip}) {
					$Inputs = ${private:-task}.Inputs
					$Outputs = ${private:-task}.Outputs
					if (${private:-task}.Partial) {
						${private:-index} = -1
						$Inputs | .{process{
							++${private:-index}
							$$ = $Outputs[${private:-index}]
							$_
						}} | & ${private:-job}
					}
					else {
						$Inputs | & ${private:-job}
					}
				}
				else {
					& ${private:-job}
				}

				if (${private:-task}.Jobs.Count -ge 2) {
					Write-BuildText DarkYellow "${private:-title} is done."
				}
			}
		}

		$_ = [System.DateTime]::Now - ${private:-task}.Started
		${private:-task}.Elapsed = $_
		Write-BuildText DarkYellow "${private:-path} is done, $_"
	}
	catch {
		${private:-task}.Elapsed = [System.DateTime]::Now - ${private:-task}.Started
		${private:-task}.Error = $_
		++$BuildInfo.ErrorCount
		++$BuildInfo.AllErrorCount
		$_ = "ERROR: Task '${private:-path}': $_"
		$null = $BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
		Write-BuildText Yellow (*Fix* ${private:-task})
		throw
	}
	finally {
		$null = $BuildInfo.Tasks.Add(${private:-task}), $BuildInfo.AllTasks.Add(${private:-task})
	}
}

function *Try-Task*($Try, $Task)
{
	$it = $BuildList[$Try]
	if (!$it.If) { return }

	if ($it.Jobs -contains $Task) {
		if ($it.Try -notcontains $Task) {
			"Task '$Try' calls failed '$Task' not protected."
		}
		return
	}

	foreach($_ in $it.Jobs) { if ($_ -is [string]) {
		$why = *Try-Task* $_ $Task
		if ($why) { return $why }
	}}
}

function *Hook*
{
	if ($BuildHook) {
		${private:-hook} = $BuildHook[$args[0]]
		if (${private:-hook}) { . ${private:-hook} }
	}
}

function *Test-Task*($Task) {
	foreach($_ in $Task) {
		$it = $BuildList[$_]
		if (!$it) {
			*Die* "Task '$_' is not defined." ObjectNotFound $_
		}
		*Test-Tree* $it ([System.Collections.ArrayList]@())
	}
}

function *Test-Tree*($Task, $Done)
{
	$count = 1 + $Done.Add($Task)
	foreach($_ in $Task.Jobs) { if ($_ -is [string]) {
		$job = $BuildList[$_]
		if (!$job) {
			*Die* "Task '$($Task.Name)': Task '$_' is not defined.`r`n$(*Fix* $Task)" ObjectNotFound
		}
		if ($Done.Contains($job)) {
			*Die* "Task '$($Task.Name)': Cyclic reference to '$_'.`r`n$(*Fix* $Task)" InvalidOperation
		}
		*Test-Tree* $job $Done
		$Done.RemoveRange($count, $Done.Count - $count)
	}}
}

function *Summary*($State, $TaskCount, $ErrorCount, $WarningCount, $Elapsed)
{
	if ($State -lt 0) {
		$text = 'Build FAILED'
		$color = 'Red'
	}
	elseif ($ErrorCount) {
		$text = 'Build completed with errors'
		$color = 'Red'
	}
	elseif ($WarningCount) {
		$text = 'Build succeeded with warnings'
		$color = 'Yellow'
	}
	else {
		$text = 'Build succeeded'
		$color = 'Green'
	}

	Write-BuildText $color "$text. $TaskCount tasks, $ErrorCount errors, $WarningCount warnings, $Elapsed"
}

### File
$ErrorActionPreference = 'Stop'
${private:-location} = $PSCmdlet.GetUnresolvedProviderPathFromPSPath('')
try {
	if ($File) {
		$BuildFile = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($File)
		if (!([System.IO.File]::Exists($BuildFile))) {
			throw "Build file does not exist: '$BuildFile'."
		}
	}
	else {
		$BuildFile = Get-BuildFile ${private:-location}
		if (!$BuildFile) {
			$BuildFile = *Hook* GetFile
		}
		if (!$BuildFile) {
			throw "Default build file is not found."
		}
	}
	$BuildRoot = Split-Path $BuildFile
}
catch {
	*Die* "$_" ObjectNotFound $File
}

### Init
${private:-parent} = $PSCmdlet.SessionState.PSVariable.Get('BuildInfo')
if (${private:-parent}) {
	if (${private:-parent}.Description -eq 'cf62724cbbc24adea925ea0e73598492') {
		${private:-parent} = ${private:-parent}.Value
	}
	else {
		${private:-parent} = $null
	}
}
if (!${private:-parent}) {
	Set-Alias Invoke-Build $MyInvocation.MyCommand.Path
}
$BuildTask = $Task
$BuildHook = $Hook
${private:-result} = $Result
${private:cf62724cbbc24adea925ea0e73598492} = $Parameters
New-Variable -Name BuildList -Option Constant -Value ([System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase))
New-Variable -Name BuildInfo -Option Constant -Description cf62724cbbc24adea925ea0e73598492 -Value `
(Select-Object AllTasks, AllMessages, AllErrorCount, AllWarningCount, Tasks, Messages, ErrorCount, WarningCount, Started, Elapsed -InputObject 1)
$BuildInfo.AllTasks = [System.Collections.ArrayList]@()
$BuildInfo.AllMessages = [System.Collections.ArrayList]@()
$BuildInfo.AllErrorCount = 0
$BuildInfo.AllWarningCount = 0
$BuildInfo.Tasks = [System.Collections.ArrayList]@()
$BuildInfo.Messages = [System.Collections.ArrayList]@()
$BuildInfo.ErrorCount = 0
$BuildInfo.WarningCount = 0
$BuildInfo.Started = [System.DateTime]::Now
if ('?' -eq $Task) { $WhatIf = $true }
if ($Result) {
	if ('?' -eq $Task) {
		New-Variable -Scope 1 $Result $BuildList -Force
	}
	else {
		New-Variable -Scope 1 $Result $BuildInfo -Force
	}
}
Remove-Variable Task, File, Parameters, Result, Hook

${private:-state} = 0
try {
	### Script
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') $BuildFile"
	${private:_} = if (${private:cf62724cbbc24adea925ea0e73598492}) { . $BuildFile @cf62724cbbc24adea925ea0e73598492 } else { . $BuildFile }
	if (!$BuildList.Count) {
		*Die* "There is no task in the script." InvalidOperation $BuildFile
	}
	$_
	foreach($_ in $_) { if ($_ -is [scriptblock]) {
		*Die* "Invalid build script syntax at the script block {$_}" InvalidOperation
	}}

	### Alter
	foreach(${private:-task} in $BuildList.Values) {
		try {
			$_ = ${private:-task}.Before
			if ($_) {
				*Alter* ${private:-task}.Name $_
			}
			$_ = ${private:-task}.After
			if ($_) {
				*Alter* ${private:-task}.Name $_ -After
			}
		}
		catch {
			*Die* "Task '$(${private:-task}.Name)': $_`r`n$(*Fix* ${private:-task})" InvalidArgument
		}
	}

	### List
	if ('?' -eq $BuildTask) {
		*Test-Task* $BuildList.Keys
		if (!${private:-result}) {
			foreach($_ in $BuildList.Values) {
				"$($_.Name) $(($_.Jobs | %{ if ($_ -is [string]) {$_} else {'{..}'} }) -join ', ') $($_.Info.ScriptName):$($_.Info.ScriptLineNumber)"
			}
		}
		return
	}

	### Check
	if ('*' -eq $BuildTask) {
		*Test-Task* $BuildList.Keys
		$BuildTask = foreach($_ in $BuildList.Keys) {
			foreach(${private:-task} in $BuildList.Values) {
				if (${private:-task}.Jobs -contains $_) {
					$_ = $null
					break
				}
			}
			if ($_) { $_ }
		}
	}
	else {
		if (!$BuildTask -or '.' -eq $BuildTask) {
			$BuildTask = if ($BuildList.Contains('.')) {'.'} else {$BuildList.Item(0).Name}
		}
		*Test-Task* $BuildTask
	}

	### Build
	foreach($_ in $BuildTask) {
		*Task* $_
	}
	${private:-state} = 1
}
catch {
	${private:-state} = -1
	throw
}
finally {
	Set-Location -LiteralPath ${private:-location} -ErrorAction Stop
	if (${private:-state}) {
		$BuildInfo.Elapsed = [System.DateTime]::Now - $BuildInfo.Started
		$BuildInfo.Messages
		*Summary* ${private:-state} $BuildInfo.Tasks.Count $BuildInfo.ErrorCount $BuildInfo.WarningCount $BuildInfo.Elapsed

		if (${private:-parent}) {
			${private:-parent}.AllTasks.AddRange($BuildInfo.AllTasks)
			${private:-parent}.AllMessages.AddRange($BuildInfo.AllMessages)
			${private:-parent}.AllErrorCount += $BuildInfo.AllErrorCount
			${private:-parent}.AllWarningCount += $BuildInfo.AllWarningCount
		}
		else {
			if ($BuildInfo.AllTasks.Count -ne $BuildInfo.Tasks.Count) {
				$BuildInfo.AllMessages
				*Summary* ${private:-state} $BuildInfo.AllTasks.Count $BuildInfo.AllErrorCount $BuildInfo.AllWarningCount $BuildInfo.Elapsed
			}
		}
	}
}
