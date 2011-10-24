
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
	[System.Version]'1.0.37'
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Add-BuildTask
{
	[CmdletBinding(DefaultParameterSetName="All")]
	param
	(
		[Parameter(Position = 0, Mandatory = $true)][string]$Name,
		[Parameter(Position = 1)][object[]]$Jobs,
		[Parameter()][object]$If = $true,
		[Parameter(ParameterSetName='Incremental')][hashtable]$Incremental,
		[Parameter(ParameterSetName='Partial')][hashtable]$Partial,
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

		switch($PSCmdlet.ParameterSetName)
		{
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
		Invoke-BuildError "Task '$Name': $_" InvalidArgument
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
		Invoke-BuildError "Task '$Task' is not defined." ObjectNotFound $Task
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
				Invoke-BuildError "PowerShell or environment variable '$Name' is not defined." ObjectNotFound $Name
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
			Invoke-BuildError "Assertion failed: $Message" InvalidOperation
		}
		else {
			Invoke-BuildError 'Assertion failed.' InvalidOperation
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
		Invoke-BuildError "The command {${private:-Command}} exited with code $LastExitCode." InvalidResult $LastExitCode
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
			Invoke-BuildError $_ InvalidArgument $Path
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
	[Parameter()][System.ConsoleColor]$Color,
	[Parameter()][string]$Text
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

function Invoke-BuildError([string]$Message, [System.Management.Automation.ErrorCategory]$Category = 0, $Target)
{
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]$Message), $null, $Category, $Target))
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

if (!$Host.UI -or !$Host.UI.RawUI) {
	function Write-BuildText([Parameter()][System.ConsoleColor]$Color, [Parameter()][string]$Text) { $Text }
}

function Write-Warning([string]$Message)
{
	$_ = "WARNING: " + $Message
	Write-BuildText Yellow $_
	++$BuildInfo.WarningCount
	++$BuildInfo.AllWarningCount
	$null = $BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
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
		Invoke-BuildError "Invalid pair, expected hashtable @{value1 = value2}." InvalidArgument
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
	${private:-do-input} = $true
	${private:-no-input} = $false
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
					$why = *Try-Task* ${private:-job}
					if ($why) {
						Write-BuildText Red $why
						throw
					}
					else {
						Write-BuildText Red ($BuildList[${private:-job}].Error | Out-String)
					}
				}
			}
			else {
				${private:-title} = "${private:-path} (${private:-number}/${private:-count})"
				Write-BuildText DarkYellow "${private:-title}:"

				if ($WhatIf) {
					${private:-job}
					continue
				}

				if (${private:-do-input}) {
					${private:-do-input} = $false
					if ($null -ne ${private:-task}.Inputs) {
						${private:-no-input} = *IO* ${private:-task}
					}
				}

				if (${private:-no-input}) {
					Write-BuildText DarkYellow ${private:-no-input}
					continue
				}

				Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
				if ($null -eq ${private:-no-input}) {
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

function *Try-Task*($TryTask)
{
	foreach($_ in $BuildTask) {
		$why = *Try-Tree* $_ $TryTask
		if ($why) { return $why }
	}
}

function *Try-Tree*($Task, $TryTask)
{
	$it = $BuildList[$Task]
	if (!$it.If) { return }

	if ($it.Jobs -contains $TryTask) {
		if ($it.Try -notcontains $TryTask) {
			"Task '$Task' calls failed '$TryTask' not protected."
		}
		return
	}

	foreach($_ in $it.Jobs) { if ($_ -is [string]) {
		$why = *Try-Tree* $_ $TryTask
		if ($why) { return $why }
	}}
}

function *Preprocess*($Task, $Done)
{
	if (!$Task.If) { return }

	$count = 1 + $Done.Add($Task)
	foreach($_ in $Task.Jobs) { if ($_ -is [string]) {
		$job = $BuildList[$_]

		if (!$job) {
			Invoke-BuildError "Task '$($Task.Name)': Task '$_' is not defined.`r`n$(*Fix* $Task)" ObjectNotFound
		}

		if ($Done.Contains($job)) {
			Invoke-BuildError "Task '$($Task.Name)': Cyclic reference to '$_'.`r`n$(*Fix* $Task)" InvalidOperation
		}

		*Preprocess* $job $Done
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

### Resolve script
$ErrorActionPreference = 'Stop'
${private:-location} = $PSCmdlet.GetUnresolvedProviderPathFromPSPath('')
try {
	if ($File) {
		$BuildFile = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($File)
		if (!([System.IO.File]::Exists($BuildFile))) {
			throw "Script does not exist: '$BuildFile'."
		}
	}
	else {
		$BuildFile = @([System.IO.Directory]::GetFiles(${private:-location}, '*.build.ps1'))
		if (!$BuildFile) {
			throw "Found no '*.build.ps1' files."
		}

		if ($BuildFile.Count -eq 1) {
			$BuildFile = $BuildFile[0]
		}
		else {
			$BuildFile = foreach($BuildFile in $BuildFile) {
				if ([System.IO.Path]::GetFileName($BuildFile) -eq '.build.ps1') {
					$BuildFile
					break
				}
			}
			if (!$BuildFile) {
				throw "Found more than one '*.build.ps1' and none of them is '.build.ps1'."
			}
		}
	}
	$BuildRoot = Split-Path $BuildFile
}
catch {
	Invoke-BuildError "$_" ObjectNotFound $File
}

### Set variables
${private:-parent} = $PSCmdlet.SessionState.PSVariable.Get('BuildInfo')
if (${private:-parent}) {
	if (${private:-parent}.Description -eq 'cf62724cbbc24adea925ea0e73598492') {
		${private:-parent} = ${private:-parent}.Value
	}
	else {
		${private:-parent} = $null
	}
}
else {
	Set-Alias Invoke-Build $MyInvocation.MyCommand.Path
}
$BuildTask = $Task
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
Remove-Variable Task, File, Parameters, Result

${private:-state} = 0
try {
	### Invoke script
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') $BuildFile"
	${private:_} = if (${private:cf62724cbbc24adea925ea0e73598492}) { . $BuildFile @cf62724cbbc24adea925ea0e73598492 } else { . $BuildFile }
	if (!$BuildList.Count) {
		Invoke-BuildError "There is no task in the script." InvalidOperation $BuildFile
	}
	$_
	foreach($_ in $_) { if ($_ -is [scriptblock]) {
		Invoke-BuildError "Invalid build script syntax at the script block {$_}" InvalidOperation
	}}

	### Alter tasks
	foreach(${private:-task} in $BuildList.Values) {
		try {
			${private:-list} = ${private:-task}.Before
			if (${private:-list}) {
				*Alter* ${private:-task}.Name ${private:-list}
			}
			${private:-list} = ${private:-task}.After
			if (${private:-list}) {
				*Alter* ${private:-task}.Name ${private:-list} -After
			}
		}
		catch {
			Invoke-BuildError "Task '$(${private:-task}.Name)': $_." InvalidArgument
		}
	}

	### List tasks
	if ('?' -eq $BuildTask) {
		if (!${private:-result}) {
			foreach($_ in $BuildList.Values) {
				"$($_.Name) $(($_.Jobs | %{ if ($_ -is [string]) {$_} else {'{..}'} }) -join ', ') $($_.Info.ScriptName):$($_.Info.ScriptLineNumber)"
			}
		}
		return
	}

	### Default task
	if (!$BuildTask -or '.' -eq $BuildTask) {
		$BuildTask = if ($BuildList.Contains('.')) {'.'} else {$BuildList.Item(0).Name}
	}

	### Preprocess tasks
	foreach($_ in $BuildTask) {
		${private:-task} = $BuildList[$_]
		if (!${private:-task}) {
			Invoke-BuildError "Task '$_' is not defined." ObjectNotFound $_
		}
		*Preprocess* ${private:-task} ([System.Collections.ArrayList]@())
	}

	### Process tasks
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
