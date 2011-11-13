
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
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][hashtable]$Parameters,
	[hashtable]$Hook,
	[string]$Result,
	[switch]$WhatIf
)

Set-Alias assert Assert-BuildTrue
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildVersion
{
	[System.Version]'1.1.1'
}

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
		if ($it) {
			throw "Task name already exists:`r`n$(*Fix* $it)"
		}

		$it = Select-Object Name, Error, Started, Elapsed, Jobs, Try, If, Inputs, Outputs, Partial, After, Before, Info -InputObject 1
		$it.Name = $Name
		$it.Jobs = $jobList = [System.Collections.ArrayList]@()
		$it.Try = $tryList = [System.Collections.ArrayList]@()
		$it.If = $If
		$it.After = $After
		$it.Before = $Before
		$it.Info = $MyInvocation
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
			else {
				throw "Invalid job type."
			}
		}}}
	}
	catch {
		*Die* "Task '$Name': $_" InvalidArgument
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildError([Parameter(Mandatory=$true)][string]$Task)
{
	$_ = $BuildList[$Task]
	if (!$_) {
		*Die* "Task '$Task' is not defined." ObjectNotFound $Task
	}
	$_.Error
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildProperty([Parameter(Mandatory=$true)][string]$Name, $Value)
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
function Assert-BuildTrue([Parameter()]$Condition, [string]$Message)
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
function Invoke-BuildExec([Parameter(Mandatory=$true)][scriptblock]$Command, [int[]]$ExitCode = 0)
{
	${private:-Command} = $Command
	${private:-ExitCode} = $ExitCode
	Remove-Variable Command, ExitCode

	. ${-Command}
	if (${-ExitCode} -notcontains $LastExitCode) {
		*Die* "The command {${-Command}} exited with code $LastExitCode." InvalidResult $LastExitCode
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Use-BuildAlias([Parameter()][string]$Path, [Parameter(Mandatory=$true)][string[]]$Name)
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
		foreach($_ in $files) { if ([System.IO.Path]::GetFileName($_) -eq '.build.ps1') { return $_ } }
	}
}

if ($MyInvocation.InvocationName -eq '.') {
	"Invoke-Build.ps1 Version $(Get-BuildVersion)`r`nCopyright (c) 2011 Roman Kuzmin"
	'task', 'use', 'exec', 'assert', 'property', 'error', 'Get-BuildVersion','Write-BuildText' |
	.{process{ Get-Help $_ }} | Format-Table Name, Synopsis -AutoSize | Out-String
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

function *Alter*($Add, $Tasks, [switch]$After)
{
	foreach($_ in $Tasks) {
		$ref, $data = *Ref* $_
		$it = $BuildList[$ref]
		if (!$it) {
			throw "Task '$ref' is not defined."
		}

		$jobs = $it.Jobs
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

		$jobs.Insert($index, $Add)
		if (1 -eq $data) {
			$null = $it.Try.Add($Add)
		}
	}
}

function *KV*($Hash)
{
	if ($Hash.Count -ne 1) {
		throw "Invalid pair, expected hashtable @{X = Y}."
	}
	$Hash.Keys
	$Hash.Values
}

function *Ref*($Ref)
{
	if ($Ref -is [hashtable]) { *KV* $Ref } else { $Ref }
}

function *Fix*($Task)
{
	$Task.Info.PositionMessage.Trim().Replace("`n", "`r`n")
}

function *IO*($Task)
{
	${private:-Task} = $Task
	Remove-Variable Task

	${private:-inputs} = ${-Task}.Inputs
	if (${-inputs} -is [scriptblock]) {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		${-inputs} = @(& ${-inputs})
	}

	${private:-paths} = [System.Collections.ArrayList]@()
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	${-inputs} = foreach(${private:-in} in ${-inputs}) {
		if (${-in} -isnot [System.IO.FileInfo]) {
			${-in} = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath(${-in})
			if (!${-in}.Exists) {
				throw "Input file does not exist: '${-in}'."
			}
		}
		$null = ${-paths}.Add(${-in}.FullName)
		${-in}
	}

	if (!${-paths}) {
		'Skipping because there is no input.'
		return
	}

	if (${-Task}.Partial) {
		${private:-outputs} = @(if (${-Task}.Outputs -is [scriptblock]) {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${-paths} | & ${-Task}.Outputs
		}
		else {
			${-Task}.Outputs
		})
		if (${-paths}.Count -ne ${-outputs}.Count) {
			throw "Different input and output counts: $(${-paths}.Count) and $(${-outputs}.Count)."
		}

		$$ = -1
		$inputs2 = [System.Collections.ArrayList]@()
		$outputs2 = [System.Collections.ArrayList]@()
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${-inputs}) {
			++$$
			$path = ${-outputs}[$$]
			$file = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($path)
			if (!$file.Exists -or ($_.LastWriteTime -gt $file.LastWriteTime)) {
				$null = $inputs2.Add(${-paths}[$$]), $outputs2.Add($path)
			}
		}

		if ($inputs2) {
			${-Task}.Inputs = $inputs2
			${-Task}.Outputs = $outputs2
			return
		}
	}
	else {
		${-Task}.Inputs = ${-paths}

		if (${-Task}.Outputs -is [scriptblock]) {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${-Task}.Outputs = & ${-Task}.Outputs
			if (!${-Task}.Outputs) {
				throw 'Incremental output cannot be empty.'
			}
		}

		$max = (${-inputs} | .{process{ $_.LastWriteTime.Ticks }} | Measure-Object -Maximum).Maximum
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${-Task}.Outputs) {
			$_ = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)
			if (!$_.Exists -or $_.LastWriteTime.Ticks -lt $max) {
				return
			}
		}
	}
	'Skipping because all outputs are up-to-date with respect to the inputs.'
}

function *Task*($Name, $Path)
{
	${private:-it} = $BuildList[$Name]
	${private:-path} = if ($Path) { "$Path/$(${-it}.Name)" } else { ${-it}.Name }
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
					if (${-it}.Try -notcontains ${-job}) {
						throw
					}
					foreach($it in $BuildTask) {
						$why = *Try-Task* $it ${-job}
						if ($why) {
							Write-BuildText Red $why
							throw
						}
					}
					Write-BuildText Red ($_ | Out-String)
				}
			}
			else {
				${private:-title} = "${-path} (${-n}/${-count})"
				Write-BuildText DarkYellow "${-title}:"

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
						${private:-index} = -1
						$Inputs | .{process{
							++${-index}
							$$ = $Outputs[${-index}]
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
					Write-BuildText DarkYellow "Done ${-title}"
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
		$_ = "ERROR: Task '${-path}': $_"
		$null = $BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
		Write-BuildText Yellow (*Fix* ${-it})
		throw
	}
	finally {
		$null = $BuildInfo.Tasks.Add(${-it}), $BuildInfo.AllTasks.Add(${-it})
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
		if (${-hook}) { . ${-hook} }
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
		$it = $BuildList[$_]
		if (!$it) {
			*Die* "Task '$($Task.Name)': Task '$_' is not defined.`r`n$(*Fix* $Task)" ObjectNotFound
		}
		if ($Done.Contains($it)) {
			*Die* "Task '$($Task.Name)': Cyclic reference to '$_'.`r`n$(*Fix* $Task)" InvalidOperation
		}
		*Test-Tree* $it $Done
		$Done.RemoveRange($count, $Done.Count - $count)
	}}
}

function *Summary*($State, $Tasks, $Errors, $Warnings, $Span)
{
	$color, $text = if ($State -eq 2) { 'Red', 'Build FAILED' }
	elseif ($Errors) { 'Red', 'Build completed with errors' }
	elseif ($Warnings) { 'Yellow', 'Build succeeded with warnings' }
	else { 'Green', 'Build succeeded' }
	Write-BuildText $color "$text. $Tasks tasks, $Errors errors, $Warnings warnings, $Span"
}

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
		$BuildFile = Get-BuildFile ${-location}
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

${private:-parent} = $PSCmdlet.SessionState.PSVariable.Get('BuildInfo')
if (${-parent}) {
	if (${-parent}.Description -eq 'cf62724cbbc24adea925ea0e73598492') {
		${-parent} = ${-parent}.Value
	}
	else {
		${-parent} = $null
	}
}
if (!${-parent}) {
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
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') $BuildFile"
	$private:_ = if ($cf62724cbbc24adea925ea0e73598492) { . $BuildFile @cf62724cbbc24adea925ea0e73598492 } else { . $BuildFile }
	if (!$BuildList.Count) {
		*Die* "There is no task in the script." InvalidOperation $BuildFile
	}
	$_
	foreach($_ in $_) { if ($_ -is [scriptblock]) {
		*Die* "Invalid build script syntax at the script block {$_}" InvalidOperation
	}}

	foreach(${private:-it} in $BuildList.Values) {
		try {
			$_ = ${-it}.Before
			if ($_) {
				*Alter* ${-it}.Name $_
			}
			$_ = ${-it}.After
			if ($_) {
				*Alter* ${-it}.Name $_ -After
			}
		}
		catch {
			*Die* "Task '$(${-it}.Name)': $_`r`n$(*Fix* ${-it})" InvalidArgument
		}
	}

	if ('?' -eq $BuildTask) {
		*Test-Task* $BuildList.Keys
		if (!${-result}) {
			foreach($_ in $BuildList.Values) {
				"$($_.Name) $(($_.Jobs | %{ if ($_ -is [string]) {$_} else {'{..}'} }) -join ', ') $($_.Info.ScriptName):$($_.Info.ScriptLineNumber)"
			}
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
			if ($_) { $_ }
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
	${-state} = 1
}
catch {
	${-state} = 2
	throw
}
finally {
	Set-Location -LiteralPath ${-location} -ErrorAction Stop
	if (${-state}) {
		$BuildInfo.Elapsed = [System.DateTime]::Now - $BuildInfo.Started
		$BuildInfo.Messages
		*Summary* ${-state} $BuildInfo.Tasks.Count $BuildInfo.ErrorCount $BuildInfo.WarningCount $BuildInfo.Elapsed

		if (${-parent}) {
			${-parent}.AllTasks.AddRange($BuildInfo.AllTasks)
			${-parent}.AllMessages.AddRange($BuildInfo.AllMessages)
			${-parent}.AllErrorCount += $BuildInfo.AllErrorCount
			${-parent}.AllWarningCount += $BuildInfo.AllWarningCount
		}
		else {
			if ($BuildInfo.AllTasks.Count -ne $BuildInfo.Tasks.Count) {
				$BuildInfo.AllMessages
				*Summary* ${-state} $BuildInfo.AllTasks.Count $BuildInfo.AllErrorCount $BuildInfo.AllWarningCount $BuildInfo.Elapsed
			}
		}
	}
}
