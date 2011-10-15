
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
	[Parameter(Position = 0)]
	[string[]]$Task
	,
	[Parameter(Position = 1)]
	[string]$File
	,
	[Parameter(Position = 2)]
	[hashtable]$Parameters
	,
	[Parameter()]
	[string]$Result
	,
	[Parameter()]
	[switch]$WhatIf
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
	[System.Version]'1.0.31'
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Add-BuildTask
(
	[Parameter(Position = 0, Mandatory = $true)]
	[string]$Name
	,
	[Parameter(Position = 1)]
	[object[]]$Jobs
	,
	[Parameter()]
	[object]$If = $true
	,
	[Parameter()]
	[hashtable]$Incremental
	,
	[Parameter()]
	[hashtable]$Partial
	,
	[Parameter()]
	[object[]]$After
	,
	[Parameter()]
	[object[]]$Before
)
{
	$_ = $BuildList[$Name]
	if ($_) {
		Invoke-BuildError @"
Task '$Name' is added twice.
$(Invoke-Build-Fix $_.Info.PositionMessage)
"@ InvalidOperation $Name
	}

	$jobList = [System.Collections.ArrayList]@()
	$tryList = [System.Collections.ArrayList]@()

	$_ = Select-Object Name, Error, Started, Elapsed, Jobs, Try, If, Inputs, Outputs, Partial, After, Before, Info -InputObject 1
	$_.Name = $Name
	$_.Jobs = $jobList
	$_.Try = $tryList
	$_.If = $If
	$_.After = $After
	$_.Before = $Before
	$_.Info = $MyInvocation

	if ($Incremental -or $Partial) {
		if ($Incremental -and $Partial) {
			Invoke-BuildError "Task '$Name': Parameters Incremental and Partial cannot be used together." InvalidArgument
		}
		if ($Incremental) {
			$IO = $Incremental
		}
		else {
			$IO = $Partial
			$_.Partial = $true
		}
		if ($IO.Count -ne 1) {
			Invoke-BuildError "Task '$Name': Invalid Incremental/Partial hashtable. Valid form: @{ Inputs = Outputs }." InvalidArgument $IO
		}
		$_.Inputs = @($IO.Keys)[0]
		$_.Outputs = @($IO.Values)[0]
	}

	if ($Jobs) {
		foreach($job in $Jobs) {
			$name2, $data = Invoke-Build-Pair $Name $job
			if ($data) {
				$null = $jobList.Add($name2)
				if (1 -eq $data) {
					$null = $tryList.Add($name2)
				}
			}
			elseif (($job -is [string]) -or ($job -is [scriptblock])) {
				$null = $jobList.Add($job)
			}
			else {
				Invoke-BuildError "Task '$Name': Invalid job type." InvalidArgument $job
			}
		}
	}

	$BuildList.Add($Name, $_)
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildError
(
	[Parameter(Mandatory = $true)]
	[string]$Task
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
	[Parameter(Mandatory = $true)]
	[string]$Name
	,
	[Parameter()]
	$Value
)
{
	$_ = $ExecutionContext.SessionState.PSVariable.GetValue($Name)
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
	[Parameter()]
	$Condition
	,
	[Parameter()]
	[string]$Message
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
	[Parameter(Mandatory = $true)]
	[scriptblock]$Command
	,
	[Parameter()]
	[int[]]$ExitCode = 0
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
	[Parameter()]
	[string]$Path
	,
	[Parameter(Mandatory = $true)]
	[string[]]$Name
)
{
	if ($PSCmdlet.MyInvocation.InvocationName -eq '.') {
		Invoke-BuildError "Use-BuildAlias should not be dot-sourced." InvalidOperation
	}

	if ($Path) {
		if ($Path.StartsWith('Framework', [System.StringComparison]::OrdinalIgnoreCase)) {
			$dir = "$env:windir\Microsoft.NET\$Path"
			if (![System.IO.Directory]::Exists($dir)) {
				Invoke-BuildError "Directory does not exist: '$dir'." InvalidArgument $Path
			}
		}
		else {
			try { $dir = Convert-Path (Resolve-Path -LiteralPath $Path -ErrorAction Stop) }
			catch { Invoke-BuildError $_ InvalidArgument $Path }
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
	[Parameter()]
	[System.ConsoleColor]$Color
	,
	[Parameter()]
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

function Invoke-BuildError
(
	[string]$Message
	,
	[System.Management.Automation.ErrorCategory]$Category = 0
	,
	$Target
)
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
	$null = $BuildInfo.Messages.Add($_)
	$null = $BuildInfo.AllMessages.Add($_)
}

function Invoke-Build-Alter([string]$Extra, $Tasks, [switch]$After)
{
	foreach($_ in $Tasks) {
		$name, $data = Invoke-Build-Pair $Extra $_
		$task = $BuildList[$name]
		if (!$task) {
			Invoke-BuildError "Task '$Extra': Task '$name' is not defined." InvalidArgument $_
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

function Invoke-Build-Pair([string]$Task, $Pair)
{
	if ($Pair -is [hashtable]) {
		if ($Pair.Count -ne 1) {
			Invoke-BuildError "Task '$Task': Hashtable task reference should have one item." InvalidArgument $Pair
		}
		@($Pair.Keys)[0]
		@($Pair.Values)[0]
	}
	else {
		$Pair
	}
}

function Invoke-Build-Fix([string]$Text)
{
	$Text.Trim().Replace("`n", "`r`n")
}

function Invoke-Build-If([object]$Task)
{
	${private:-Task} = $Task
	Remove-Variable Task

	try {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		& ${private:-Task}.If
	}
	catch {
		${private:-Task}.Error = $_
		throw
	}
}

function Invoke-Build-IO([object]$Task)
{
	${private:-Task} = $Task
	Remove-Variable Task

	${private:-inputs} = ${private:-Task}.Inputs

	if (${private:-inputs} -is [scriptblock]) {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		${private:-inputs} = @(& ${private:-inputs})
	}

	${private:-paths} = [System.Collections.ArrayList]@()
	try {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		${private:-inputs} = foreach(${private:-in} in ${private:-inputs}) {
			if (${private:-in} -isnot [System.IO.FileSystemInfo]) {
				${private:-in} = Get-Item -LiteralPath ${private:-in} -Force -ErrorAction Stop
			}
			$null = ${private:-paths}.Add(${private:-in}.FullName)
			${private:-in}
		}
	}
	catch {
		throw "Error on resolving inputs: $_"
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

		${private:-index} = -1
		${private:-inputs2} = [System.Collections.ArrayList]@()
		${private:-outputs2} = [System.Collections.ArrayList]@()
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach(${private:-in} in ${private:-inputs}) {
			++${private:-index}
			${private:-out} = ${private:-outputs}[${private:-index}]
			if (!(Test-Path -LiteralPath ${private:-out}) -or (${private:-in}.LastWriteTime -gt (Get-Item -LiteralPath ${private:-out} -Force).LastWriteTime)) {
				$null = ${private:-inputs2}.Add(${private:-paths}[${private:-index}])
				$null = ${private:-outputs2}.Add(${private:-out})
			}
		}

		if (${private:-inputs2}) {
			${private:-Task}.Inputs = ${private:-inputs2}
			${private:-Task}.Outputs = ${private:-outputs2}
		}
		else {
			'Skipping because all outputs are up-to-date with respect to the inputs.'
		}
	}
	else {
		${private:-Task}.Inputs = ${private:-paths}

		if (${private:-Task}.Outputs -is [scriptblock]) {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${private:-Task}.Outputs = & ${private:-Task}.Outputs
			if (!${private:-Task}.Outputs) {
				throw 'Incremental output is empty. Expected at list one item.'
			}
		}

		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach(${private:-out} in ${private:-Task}.Outputs) {
			if (!(Test-Path -LiteralPath ${private:-out} -ErrorAction Stop)) {
				return
			}
		}

		${private:-time1} = ${private:-inputs} |
		.{process{ $_.LastWriteTime.Ticks }} | Measure-Object -Maximum

		${private:-time2} = Get-Item -LiteralPath ${private:-Task}.Outputs -Force -ErrorAction Stop |
		.{process{ $_.LastWriteTime.Ticks }} | Measure-Object -Minimum

		if (${private:-time1}.Maximum -le ${private:-time2}.Minimum) {
			'Skipping because all outputs are up-to-date with respect to the inputs.'
		}
	}
}

function Invoke-Build-Task($Name, $Path)
{
	${private:-task} = $BuildList[$Name]
	${private:-path} = if ($Path) { "$Path/$(${private:-task}.Name)" } else { ${private:-task}.Name }

	if (${private:-task}.Error) {
		Write-BuildText Yellow "${private:-path} failed before."
		return
	}

	if (${private:-task}.Started) {
		Write-BuildText DarkYellow "${private:-path} was done before."
		return
	}

	Remove-Variable Name, Path

	${private:-if} = ${private:-task}.If
	if (${private:-if} -is [scriptblock]) {
		if (!(Invoke-Build-If ${private:-task})) {
			return
		}
	}
	elseif (!${private:-if}) {
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
					Invoke-Build-Task ${private:-job} ${private:-path}
				}
				catch {
					if (${private:-task}.Try -notcontains ${private:-job}) {
						throw
					}
					${private:-why} = Invoke-Build-Try-Task ${private:-job}
					if (${private:-why}) {
						Write-BuildText Red ${private:-why}
						throw
					}
					else {
						${private:-job} = $BuildList[${private:-job}]
						Write-BuildText Red (${private:-job}.Error | Out-String)
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
						${private:-no-input} = Invoke-Build-IO ${private:-task}
					}
				}

				if (${private:-no-input}) {
					Write-BuildText DarkYellow ${private:-no-input}
				}
				else {
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
		}

		${private:-elapsed} = [System.DateTime]::Now - ${private:-task}.Started
		${private:-task}.Elapsed = ${private:-elapsed}
		Write-BuildText DarkYellow "${private:-path} is done, ${private:-elapsed}"
	}
	catch {
		${private:-task}.Elapsed = [System.DateTime]::Now - ${private:-task}.Started
		${private:-task}.Error = $_
		++$BuildInfo.ErrorCount
		++$BuildInfo.AllErrorCount
		$_ = "ERROR: Task '${private:-path}': $_"
		$null = $BuildInfo.Messages.Add($_)
		$null = $BuildInfo.AllMessages.Add($_)
		Write-BuildText Yellow (Invoke-Build-Fix ${private:-task}.Info.PositionMessage)
		throw
	}
	finally {
		$null = $BuildInfo.Tasks.Add(${private:-task})
		$null = $BuildInfo.AllTasks.Add(${private:-task})
	}
}

function Invoke-Build-Try-Task([string]$TryTask)
{
	foreach($name in $BuildTask) {
		$why = Invoke-Build-Try-Tree $name $TryTask
		if ($why) {
			return $why
		}
	}
}

function Invoke-Build-Try-Tree([string]$Task, [string]$TryTask)
{
	$it = $BuildList[$Task]
	if (!$it.If) {
		return
	}

	if ($it.Jobs -contains $TryTask) {
		if ($it.Try -notcontains $TryTask) {
			"Fatal: Task '$Task' calls failed '$TryTask' not protected."
		}
		return
	}

	foreach($job in $it.Jobs) {
		if ($job -is [string]) {
			$why = Invoke-Build-Try-Tree $job $TryTask
			if ($why) {
				return $why
			}
		}
	}
}

function Invoke-Build-Preprocess([object]$Task, [Collections.ArrayList]$Done)
{
	if (!$Task.If) {
		Write-BuildText DarkGray "$($Task.Name) is excluded."
		return
	}

	$count = 1 + $Done.Add($Task)

	foreach($_ in $Task.Jobs) {
		if ($_ -is [string]) {
			$job = $BuildList[$_]

			if (!$job) {
				Invoke-BuildError @"
Task '$($Task.Name)': Task '$_' is not defined.
$(Invoke-Build-Fix $Task.Info.PositionMessage)
"@ ObjectNotFound $_
			}

			if ($Done.Contains($job)) {
				Invoke-BuildError @"
Task '$($Task.Name)': Cyclic reference to '$_'.
$(Invoke-Build-Fix $Task.Info.PositionMessage)
"@ InvalidOperation $_
			}

			Invoke-Build-Preprocess $job $Done
			$Done.RemoveRange($count, $Done.Count - $count)
		}
	}
}

function Invoke-Build-Summary($State, $TaskCount, $ErrorCount, $WarningCount, $Elapsed)
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

### Resolve the file
$ErrorActionPreference = 'Stop'
try {
	if ($File) {
		$BuildFile = (Get-Item -LiteralPath $File -Force).FullName
	}
	else {
		$BuildFile = @([System.IO.Directory]::GetFiles((Get-Location).ProviderPath, '*.build.ps1'))
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

### Set the variables
${private:-location} = Get-Location
${private:-parent} = $ExecutionContext.SessionState.PSVariable.Get('BuildInfo')
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

### Start
${private:-state} = 0
try {
	### Invoke the script
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') $BuildFile"
	${private:-it} = if (${private:cf62724cbbc24adea925ea0e73598492}) { . $BuildFile @cf62724cbbc24adea925ea0e73598492 } else { . $BuildFile }
	foreach(${private:-it} in ${private:-it}) {
		${private:-it}
		if (${private:-it} -is [scriptblock]) {
			Invoke-BuildError "Build scripts should not output script blocks. Correct the '$BuildFile'." InvalidOperation ${private:-it}
		}
	}

	### Alter task jobs
	foreach(${private:-task} in $BuildList.Values) {
		${private:-list} = ${private:-task}.Before
		if (${private:-list}) {
			Invoke-Build-Alter ${private:-task}.Name ${private:-list}
		}
		${private:-list} = ${private:-task}.After
		if (${private:-list}) {
			Invoke-Build-Alter ${private:-task}.Name ${private:-list} -After
		}
	}

	### List the tasks
	if ('?' -eq $BuildTask) {
		if (!${private:-result}) {
			foreach($_ in $BuildList.Values) {
			@"
$($_.Name) $(($_.Jobs | %{ if ($_ -is [string]) { $_ } else { '{..}' } }) -join ', ') $($_.Info.ScriptName):$($_.Info.ScriptLineNumber)
"@
			}
		}
		return
	}

	### The default task
	if (!$BuildTask -or '.' -eq $BuildTask) {
		if (!$BuildList.Count) {
			Invoke-BuildError "There is no task in the script." InvalidOperation $BuildFile
		}
		if ($BuildList.Contains('.')) {
			$BuildTask = '.'
		}
		else {
			$BuildTask = $BuildList.Item(0).Name
		}
	}

	### Preprocess tasks
	foreach(${private:-it} in $BuildTask) {
		${private:-task} = $BuildList[${private:-it}]
		if (!${private:-task}) {
			Invoke-BuildError "Task '${private:-it}' is not defined." ObjectNotFound ${private:-it}
		}
		Invoke-Build-Preprocess ${private:-task} ([System.Collections.ArrayList]@())
	}

	### Process tasks
	foreach(${private:-it} in $BuildTask) {
		Invoke-Build-Task ${private:-it}
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
		Invoke-Build-Summary ${private:-state} $BuildInfo.Tasks.Count $BuildInfo.ErrorCount $BuildInfo.WarningCount $BuildInfo.Elapsed

		if (${private:-parent}) {
			${private:-parent}.AllTasks.AddRange($BuildInfo.AllTasks)
			${private:-parent}.AllMessages.AddRange($BuildInfo.AllMessages)
			${private:-parent}.AllErrorCount += $BuildInfo.AllErrorCount
			${private:-parent}.AllWarningCount += $BuildInfo.AllWarningCount
		}
		else {
			if ($BuildInfo.AllTasks.Count -ne $BuildInfo.Tasks.Count) {
				$BuildInfo.AllMessages
				Invoke-Build-Summary ${private:-state} $BuildInfo.AllTasks.Count $BuildInfo.AllErrorCount $BuildInfo.AllWarningCount $BuildInfo.Elapsed
			}
		}
	}
}
