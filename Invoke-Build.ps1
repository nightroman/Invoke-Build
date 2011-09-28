
<#
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* Invoke-Build.ps1 - Build Automation in PowerShell
* Copyright (c) 2011 Roman Kuzmin
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
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

### Predefined aliases
Set-Alias assert Assert-BuildTrue
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildVersion
{
	[System.Version]'1.0.23'
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
	$task = $BuildData[$Name]
	if ($task) {
		Invoke-BuildError @"
Task '$Name' is added twice:
1: $(Invoke-Build-Format-Message $task.Info.PositionMessage)
2: $(Invoke-Build-Format-Message $MyInvocation.PositionMessage)
"@ InvalidOperation $Name
	}

	if ($Incremental -and $Partial) {
		Invoke-BuildError "Task '$Name': Parameters Incremental and Partial cannot be used together."
	}

	$jobList = [System.Collections.ArrayList]@()
	$tryList = [System.Collections.ArrayList]@()

	if ($Jobs) {
		foreach($job in $Jobs) {
			$name2, $data = Invoke-Build-Reference $Name $job
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

	if ($Incremental) {
		$IO = $Incremental
		$isPartial = $false
	}
	elseif ($Partial) {
		$IO = $Partial
		$isPartial = $true
	}
	else {
		$IO = $null
		$inputs = $null
		$outputs = $null
		$isPartial = $false
	}

	if ($IO) {
		if ($IO.Count -ne 1) {
			Invoke-BuildError "Task '$Name': Invalid Incremental/Partial hashtable. Valid form: @{ Inputs = Outputs }." InvalidArgument $IO
		}
		$inputs = @($IO.Keys)[0]
		$outputs = 	@($IO.Values)[0]
	}

	$BuildData.Add($Name, (New-Object PSObject -Property @{
		Name = $Name
		Jobs = $jobList
		Try = $tryList
		If = $If
		Inputs = $inputs
		Outputs = $outputs
		Partial = $isPartial
		After = $After
		Before = $Before
		Info = $MyInvocation
		Error = $null
		Started = $null
		Elapsed = $null
	}))
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildError
(
	[Parameter(Mandatory = $true)]
	[string]$Task
)
{
	$it = $BuildData[$Task]
	if (!$it) {
		Invoke-BuildError "Task '$Task' is not defined." ObjectNotFound $Task
	}
	$it.Error
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
	if (Test-Path "Variable:\$Name") {
		Get-Variable $Name -ValueOnly
	}
	else {
		$variable = [System.Environment]::GetEnvironmentVariable($Name)
		if ($variable) {
			$variable
		}
		elseif ($null -ne $Value) {
			$Value
		}
		else {
			Invoke-BuildError "PowerShell or environment variable '$Name' is not defined." ObjectNotFound $Name
		}
	}
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
	[ValidateNotNull()]
	[int[]]$ExitCode = @(0)
)
{
	${private:-command} = $Command
	${private:-valid} = $ExitCode
	Remove-Variable Command, ExitCode

	. ${private:-command}

	if (${private:-valid} -notcontains $LastExitCode) {
		Invoke-BuildError "The command {${private:-command}} exited with code $LastExitCode." InvalidResult $LastExitCode
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
			if (!(Test-Path -LiteralPath $Path)) {
				Invoke-BuildError "Directory does not exist: '$Path'." InvalidArgument $Path
			}
			$dir = Convert-Path (Resolve-Path -LiteralPath $Path -ErrorAction Stop)
		}
	}
	else {
		$dir = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
	}

	foreach($it in $Name) {
		Set-Alias $it (Join-Path $dir $it) -Scope 1
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
	$Host.UI.RawUI.ForegroundColor = $Color
	$Text
	$Host.UI.RawUI.ForegroundColor = $saved
}

# For advanced functions to show caller locations in errors.
function Invoke-BuildError($Message, $Category = 0, $Target)
{
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]$Message), $null, $Category, $Target))
}

### End of the public zone. Exit if dot-sourced.
if ($PSCmdlet.MyInvocation.InvocationName -eq '.') {
	Write-Warning 'Invoke-Build is dot-sourced only in order to get its command help.'
	'Add-BuildTask','Get-BuildProperty','Get-BuildError','Assert-BuildTrue','Invoke-BuildExec','Use-BuildAlias','Get-BuildVersion','Write-BuildText' |
	%{ Get-Help $_ } | Format-Table Name, Synopsis -AutoSize
	return
}

# With no UI use this Write-BuildText.
if (!$Host.UI -or !$Host.UI.RawUI) {
	function Write-BuildText([Parameter()][System.ConsoleColor]$Color, [Parameter()][string]$Text) { $Text }
}

# Replaces Write-Warning to collect warnings.
function Write-Warning([string]$Message)
{
	$Message = "WARNING: " + $Message
	Write-BuildText Yellow $Message
	++$BuildInfo.WarningCount
	++$BuildInfo.AllWarningCount
	$null = $BuildInfo.Messages.Add($Message)
	$null = $BuildInfo.AllMessages.Add($Message)
}

# Adds the task to the referenced task jobs.
function Invoke-Build-Alter([string]$TaskName, $Refs, [switch]$After)
{
	foreach($ref in $Refs) {
		$name, $data = Invoke-Build-Reference $TaskName $ref

		$task = $BuildData[$name]
		if (!$task) {
			Invoke-BuildError "Task '$TaskName': Task '$name' is not defined." InvalidArgument $ref
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

		$task.Jobs.Insert($index, $TaskName)
		if (1 -eq $data) {
			$null = $task.Try.Add($TaskName)
		}
	}
}

# Gets the task name and data.
function Invoke-Build-Reference([string]$Task, $Ref)
{
	if ($Ref -is [hashtable]) {
		if ($Ref.Count -ne 1) {
			Invoke-BuildError "Task '$Task': Hashtable task reference should have one item." InvalidArgument $Ref
		}
		@($Ref.Keys)[0]
		@($Ref.Values)[0]
	}
	else {
		$Ref
	}
}

# Heals line breaks in the position message.
function Invoke-Build-Format-Message([string]$Message)
{
	$Message.Trim().Replace("`n", "`r`n")
}

# Evaluates the If condition of the task.
function Invoke-Build-If([object]$Task)
{
	${private:-task} = $Task
	Remove-Variable Task

	try {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		& ${private:-task}.If
	}
	catch {
		${private:-task}.Error = $_
		throw
	}
}

# Evaluates Inputs and Outputs and gets a reason to skip.
function Invoke-Build-IO([object]$Task)
{
	${private:-task} = $Task
	Remove-Variable Task

	${private:-inputs} = ${private:-task}.Inputs

	# invoke inputs
	if (${private:-inputs} -is [scriptblock]) {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		${private:-inputs} = @(& ${private:-inputs})
	}

	# resolve to paths and items
	${private:-paths} = [System.Collections.ArrayList]@()
	try {
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

	# no input:
	if (!${private:-paths}) {
		'Skipping because there is no input.'
		return
	}

	# evaluate outputs
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	if (${private:-task}.Partial) {

		if (${private:-task}.Outputs -is [scriptblock]) {
			${private:-outputs} = @(${private:-paths} | & ${private:-task}.Outputs)
		}
		else {
			${private:-outputs} = @(${private:-task}.Outputs)
		}
		if (${private:-paths}.Count -ne ${private:-outputs}.Count) {
			throw "Different input and output counts: $(${private:-paths}.Count) and $(${private:-outputs}.Count)."
		}

		${private:-index} = -1
		${private:-inputs2} = [System.Collections.ArrayList]@()
		${private:-outputs2} = [System.Collections.ArrayList]@()
		foreach(${private:-in} in ${private:-inputs}) {
			++${private:-index}
			${private:-out} = ${private:-outputs}[${private:-index}]
			if (!(Test-Path -LiteralPath ${private:-out}) -or (${private:-in}.LastWriteTime -gt (Get-Item -LiteralPath ${private:-out} -Force -ErrorAction Stop).LastWriteTime)) {
				$null = ${private:-inputs2}.Add(${private:-paths}[${private:-index}])
				$null = ${private:-outputs2}.Add(${private:-out})
			}
		}

		if (${private:-inputs2}) {
			${private:-task}.Inputs = ${private:-inputs2}
			${private:-task}.Outputs = ${private:-outputs2}
		}
		else {
			'Skipping because all outputs are up-to-date with respect to the inputs.'
		}
	}
	else {
		${private:-task}.Inputs = ${private:-paths}

		if (${private:-task}.Outputs -is [scriptblock]) {
			${private:-task}.Outputs = & ${private:-task}.Outputs
			if (!${private:-task}.Outputs) {
				throw "Incremental output is empty. Expected at list one item."
			}
		}

		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach(${private:-out} in ${private:-task}.Outputs) {
			if (!(Test-Path -LiteralPath ${private:-out} -ErrorAction Stop)) {
				return
			}
		}

		${private:-time1} = ${private:-inputs} |
		.{process{ $_.LastWriteTime.Ticks }} | Measure-Object -Maximum

		${private:-time2} = Get-Item -LiteralPath ${private:-task}.Outputs -Force -ErrorAction Stop |
		.{process{ $_.LastWriteTime.Ticks }} | Measure-Object -Minimum

		if (${private:-time1}.Maximum -le ${private:-time2}.Minimum) {
			'Skipping because all outputs are up-to-date with respect to the inputs.'
		}
	}
}

# This is used internally and should not be called directly.
function Invoke-Build-Task($Name, $Path)
{
	# the task
	${private:-task} = $BuildData[$Name]
	if (!${private:-task}) { throw }

	# the path, use the original name
	${private:-path} = if ($Path) { "$Path\$(${private:-task}.Name)" } else { ${private:-task}.Name }

	# 1) failed?
	if (${private:-task}.Error) {
		Write-BuildText Yellow "${private:-path} failed before."
		return
	}

	# 2) done?
	if (${private:-task}.Started) {
		Write-BuildText DarkYellow "${private:-path} was done before."
		return
	}

	Remove-Variable Name, Path

	# condition?
	${private:-if} = ${private:-task}.If
	if (${private:-if} -is [scriptblock]) {
		if (!(Invoke-Build-If ${private:-task})) {
			return
		}
	}
	elseif (!${private:-if}) {
		return
	}

	# start
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
					# die if not protected
					if (${private:-task}.Try -notcontains ${private:-job}) {
						throw
					}
					# try to survive, die
					${private:-why} = Invoke-Build-Try-Task ${private:-job}
					if (${private:-why}) {
						Write-BuildText Red ${private:-why}
						throw
					}
					# survive
					else {
						${private:-job} = $BuildData[${private:-job}]
						if (!${private:-job}) { throw }
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
		${private:-text} = "ERROR: Task '${private:-path}': $_"
		$null = $BuildInfo.Messages.Add(${private:-text})
		$null = $BuildInfo.AllMessages.Add(${private:-text})
		Write-BuildText Yellow (Invoke-Build-Format-Message ${private:-task}.Info.PositionMessage)
		throw
	}
	finally {
		$null = $BuildInfo.Tasks.Add(${private:-task})
		$null = $BuildInfo.AllTasks.Add(${private:-task})
	}
}

# Gets a reason to die on protected task errors.
function Invoke-Build-Try-Task([string]$TryTask)
{
	foreach($name in $BuildTask) {
		$why = Invoke-Build-Try-Tree $name $TryTask
		if ($why) {
			return $why
		}
	}
}

# Gets a reason to die on protected task errors.
function Invoke-Build-Try-Tree([string]$Task, [string]$TryTask)
{
	$task1 = $BuildData[$Task]
	if (!$task1) { throw }

	# ignored:
	if (!$task1.If) {
		return
	}

	# has the culprit:
	if ($task1.Jobs -contains $TryTask) {
		if ($task1.Try -notcontains $TryTask) {
			"Fatal: Task '$Task' calls failed '$TryTask' not protected."
		}
		return
	}

	# process job tasks:
	foreach($job in $task1.Jobs) {
		if ($job -is [string]) {
			$why = Invoke-Build-Try-Tree $job $TryTask
			if ($why) {
				return $why
			}
		}
	}
}

# Preprocesses the task tree.
function Invoke-Build-Preprocess([object]$Task, [Collections.ArrayList]$Done)
{
	# ignore?
	if (!$Task.If) {
		Write-BuildText DarkGray "$($Task.Name) is excluded."
		return
	}

	# add the task to the list
	$count = 1 + $Done.Add($Task)

	# process task jobs
	$number = 0
	foreach($job in $Task.Jobs) {
		++$number
		if ($job -is [string]) {
			$task2 = $BuildData[$job]

			# missing:
			if (!$task2) {
				throw @"
Task '$($Task.Name)': Job $($number): Task '$job' is not defined.
$(Invoke-Build-Format-Message $Task.Info.PositionMessage)
"@
			}

			# cyclic:
			if ($Done.Contains($task2)) {
				throw @"
Task '$($Task.Name)': Job $($number): Cyclic reference to '$job'.
$(Invoke-Build-Format-Message $Task.Info.PositionMessage)
"@
			}

			# recur
			Invoke-Build-Preprocess $task2 $Done
			$Done.RemoveRange($count, $Done.Count - $count)
		}
	}
}

# Writes build information.
function Invoke-Build-Write-Info($State, $TaskCount, $ErrorCount, $WarningCount, $Elapsed)
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

	Write-BuildText $color @"
$text. $TaskCount tasks, $ErrorCount errors, $WarningCount warnings, $Elapsed
"@
}

### Resolve the file
$ErrorActionPreference = 'Stop'
try {
	if ($File) {
		$BuildFile = Resolve-Path -LiteralPath $File -ErrorAction Stop
	}
	else {
		$BuildFile = @(Resolve-Path '*.build.ps1')
		if (!$BuildFile) {
			throw "Found no '*.build.ps1' files."
		}
		if ($BuildFile.Count -eq 1) {
			$BuildFile = $BuildFile[0]
		}
		else {
			$BuildFile = $BuildFile -match '\\\.build\.ps1$'
			if (!$BuildFile) {
				throw "Found more than one '*.build.ps1' and none of them is '.build.ps1'."
			}
		}
	}
	$BuildFile = Convert-Path $BuildFile
}
catch {
	Invoke-BuildError "$_" ObjectNotFound $File
}

### Set the variables
${private:-location} = Get-Location
${private:-parent} = Get-Variable '[B]uildInfo'
if (${private:-parent}) {
	if (${private:-parent}.Description -ne 'cf62724cbbc24adea925ea0e73598492') {
		${private:-parent} = $null
	}
	else {
		${private:-parent} = ${private:-parent}.Value
	}
}
New-Variable -Name BuildData -Option Constant -Value ([System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase))
New-Variable -Name BuildInfo -Option Constant -Description cf62724cbbc24adea925ea0e73598492 -Value (New-Object PSObject)
$BuildInfo |
Add-Member -MemberType NoteProperty -Name Tasks -Value ([System.Collections.ArrayList]@()) -PassThru |
Add-Member -MemberType NoteProperty -Name AllTasks -Value ([System.Collections.ArrayList]@()) -PassThru |
Add-Member -MemberType NoteProperty -Name Messages -Value ([System.Collections.ArrayList]@()) -PassThru |
Add-Member -MemberType NoteProperty -Name AllMessages -Value ([System.Collections.ArrayList]@()) -PassThru |
Add-Member -MemberType NoteProperty -Name ErrorCount -Value 0 -PassThru |
Add-Member -MemberType NoteProperty -Name AllErrorCount -Value 0 -PassThru |
Add-Member -MemberType NoteProperty -Name WarningCount -Value 0 -PassThru |
Add-Member -MemberType NoteProperty -Name AllWarningCount -Value 0 -PassThru |
Add-Member -MemberType NoteProperty -Name Started -Value ([System.DateTime]::Now) -PassThru |
Add-Member -MemberType NoteProperty -Name Elapsed -Value $null
New-Variable -Option Constant -Name BuildRoot -Value (Split-Path $BuildFile)
$BuildTask = $Task
${private:cf62724cbbc24adea925ea0e73598492} = $Parameters
if ($Result) { New-Variable -Scope 1 $Result $BuildInfo -Force }
Remove-Variable Task, File, Parameters, Result

### Start
${private:-state} = 0
try {
	### Invoke the script and restore error preference
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') @ $BuildFile"
	${private:-it} = if (${private:cf62724cbbc24adea925ea0e73598492}) { . $BuildFile @cf62724cbbc24adea925ea0e73598492 } else { . $BuildFile }
	$ErrorActionPreference = 'Stop'
	foreach(${private:-it} in ${private:-it}) {
		${private:-it}
		if (${private:-it} -is [scriptblock]) {
			Invoke-BuildError "Build scripts should not output script blocks. Correct the '$BuildFile'." InvalidOperation ${private:-it}
		}
	}

	### The first task
	if (!$BuildTask) {
		if (!$BuildData.Count) {
			Invoke-BuildError "There is no task in the script."
		}
		if ($BuildData.Contains('.')) {
			$BuildTask = '.'
		}
		else {
			$BuildTask = $BuildData.Item(0).Name
		}
	}

	### Alter task jobs
	foreach(${private:-task} in $BuildData.Values) {
		${private:-list} = ${private:-task}.Before
		if (${private:-list}) {
			Invoke-Build-Alter ${private:-task}.Name ${private:-list}
		}
		${private:-list} = ${private:-task}.After
		if (${private:-list}) {
			Invoke-Build-Alter ${private:-task}.Name ${private:-list} -After
		}
	}

	### View the tasks
	if ($BuildTask[0] -eq '?') {
		$BuildData.Values | .{process{
			${private:-task} = 1 | Select-Object Task, Info
			${private:-task}.Task = $_.Name
			${private:-file} = $_.Info.ScriptName
			if (${private:-file} -like "$BuildRoot\*") {
				${private:-file} = ${private:-file}.Substring($BuildRoot.Length + 1)
			}
			${private:-task}.Info = @"
$(($_.Jobs | %{ if ($_ -is [string]) { $_ } else { '{..}' } }) -join ', ') @ $(${private:-file}):$($_.Info.ScriptLineNumber)
"@
			${private:-task}
		}} | Format-Table Task, Info -AutoSize -Wrap | Out-String
		return
	}

	### Preprocess tasks
	foreach(${private:-it} in $BuildTask) {
		${private:-task} = $BuildData[${private:-it}]
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
		Invoke-Build-Write-Info ${private:-state} $BuildInfo.Tasks.Count $BuildInfo.ErrorCount $BuildInfo.WarningCount $BuildInfo.Elapsed

		if (${private:-parent}) {
			${private:-parent}.AllTasks.AddRange($BuildInfo.AllTasks)
			${private:-parent}.AllMessages.AddRange($BuildInfo.AllMessages)
			${private:-parent}.AllErrorCount += $BuildInfo.AllErrorCount
			${private:-parent}.AllWarningCount += $BuildInfo.AllWarningCount
		}
		else {
			if ($BuildInfo.AllTasks.Count -ne $BuildInfo.Tasks.Count) {
				$BuildInfo.AllMessages
				Invoke-Build-Write-Info ${private:-state} $BuildInfo.AllTasks.Count $BuildInfo.AllErrorCount $BuildInfo.AllWarningCount $BuildInfo.Elapsed
			}
		}
	}
}
