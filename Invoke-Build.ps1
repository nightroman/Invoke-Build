
<#
.Synopsis
	Invoke-Build v1.0.0.rc6 - Orchestrate Builds in PowerShell

.Description
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
	*
	* Invoke-Build - Orchestrate Builds in PowerShell
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
	*
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

	The ideas come from the psake module and many other build and make tools.
	The goal of this script is to provide a lightweight and yet robust engine.
	There is a number of cases and scenarios where this script works very well.

	The script is called directly with or without parameters, not dot-sourced.
	It is easier to use if it is located in one of the the system path folders.

	Tasks including imported from other scripts are invoked with the current
	location set to $BuildRoot which is the root of the main build script.
	Tasks may change locations and they do not have to care of restoring.

	NOTE: dot-source Invoke-Build only in order to get help for its functions.

	EXPOSED FUNCTIONS

		* Add-Task
		* Get-Error
		* Assert-True
		* Invoke-Exec
		* Use-Framework
		* Write-Color
		* Write-Warning [*]

	[*] Write-Warning is redefined internally in order to count warnings.

	EXPOSED ALIASES

		* task ~ Add-Task
		* exec ~ Invoke-Exec
		* assert ~ Assert-True

	EXPOSED VARIABLES

	Variables used by the Invoke-Build should not be visible for build scripts
	and tasks unless they are documented:

	Exposed variables designed for build scripts and tasks:

		* BuildFile - build script file path
		* BuildRoot - build script root path
		* WhatIf    - Invoke-Build parameter

	Visible but strictly for use by Invoke-Build:

		* BuildInfo, BuildThis, PSCmdlet

.Parameter Tasks
		One or more tasks to be invoked. Use '?' in order to view tasks. The
		default task is '.', just a dot.

.Parameter Build
		The build script which defined build tasks by Add-Task (task).

		If it is not specified then Invoke-Build looks for "*.build.ps1" files
		in the current location. A single file is used as the build script. If
		more than one file exists then ".build.ps1" is used as the default.

.Parameter Parameters
		The hashtable of parameters to be passed in the build script.

.Parameter WhatIf
		Tells to show preprocessed tasks and their jobs instead of invoking
		them. $WhatIf can be used in build scripts but not in tasks because
		tasks are not invoked when $WhatIf is true.

.Inputs
	None

.Outputs
	Progress, diagnostics, and error messages, and output of tasks and tools
	that they invoke. Basically output is a log of the entire build process.

.Example
	# Invoke the default (.) task from the default build script:
	Invoke-Build

.Example
	# Show the tasks from the default build script and another script:
	Invoke-Build ?
	Invoke-Build ? Another.build.ps1

.Example
	# Invoke the specified tasks from the default script with parameters:
	Invoke-Build Task1, Task2 -Parameters @{ Param1 = 'Answer', Param2 = '42' }

.Link
	https://github.com/nightroman/Invoke-Build
	PS> . Invoke-Build # Then use Get-Help, help, man for functions
	Add-Task
	Get-Error
	Assert-True
	Invoke-Exec
	Use-Framework
	Write-Color
#>

param
(
	[Parameter()]
	[string[]]$Tasks = '.'
	,
	[Parameter()]
	[string]$Build
	,
	[Parameter()]
	[hashtable]$Parameters = @{}
	,
	[Parameter()]
	[switch]$WhatIf
)

### Predefined aliases
Set-Alias task Add-Task
Set-Alias exec Invoke-Exec
Set-Alias assert Assert-True

<#
.Synopsis
	Adds the build task to the internal task list.

.Description
	This is the key function of build scripts. It creates build tasks, defines
	dependencies and invocation order, and adds the tasks to the internal list.

	Caution: Add-Task is called from build scripts (build preprocessing stage)
	but not from their tasks (build invocation stage).

	Add-Task has the predefined alias 'task'.

.Parameter Name
		The task name, any string except '?' ('?' is used to view tasks).

.Parameter Jobs
		The task jobs. The following types are supported:
		* [string] - existing task name
		* [hashtable] - @{TaskName = Option}
		* [scriptblock] - script blocks invoked for this task

		Notation @{TaskName = Option} references the task TaskName and assigns
		an Option to it. The only supported now option value is 1: protected
		task call. It tells to ignore task errors if other active tasks also
		call TaskName protected.

.Parameter If
		Tells whether to invoke the task ($true) or skip it ($false).
		The default is $true.

.Inputs
	None

.Outputs
	None

.Link
	Get-Error
#>
function Add-Task
(
	[Parameter(Position = 0, Mandatory = $true)]
	[string]$Name
	,
	[Parameter(Position = 1, Mandatory = $true)]
	[object[]]$Jobs
	,
	[Parameter()]
	[int]$If = 1
)
{
	$task = $BuildThis.Tasks[$Name]
	if ($task) {
		ThrowTerminatingError @"
Task '$Name' is added twice:
1: $(Format-PositionMessage $task.Info.PositionMessage)
2: $(Format-PositionMessage $MyInvocation.PositionMessage)
"@ InvalidOperation $Name
	}

	$try = [System.Collections.ArrayList]@()
	for($i = 0; $i -lt $Jobs.Count; ++$i) {
		if ($Jobs[$i] -is [hashtable]) {
			$hash = $Jobs[$i]
			if ($hash.Count -ne 1) {
				ThrowTerminatingError "Job $($i + 1)/$($Jobs.Count): hashtable should have one item." InvalidArgument $hash
			}
			$job = @($hash.Keys)[0]
			$Jobs[$i] = $job
			if (@($hash.Values)[0] -eq 1) {
				$null = $try.Add($job)
			}
		}
	}

	$BuildThis.Tasks.Add($Name, @{
		Name = $Name
		Jobs = $Jobs
		Info = $MyInvocation
		If = $If
		Try = $try
	})
}

<#
.Synopsis
	Gets an error of the specified task if the task has failed.

.Description
	This method is used when some task jobs are protected (@{ Task = 1 }) and
	the current task wants to analyse task errors.

.Parameter Name
		Name of the task which error is requested.

.Inputs
	None

.Outputs
	The error object or null if the task has no errors.

.Link
	Add-Task
#>
function Get-Error
(
	[Parameter(Mandatory = $true)]
	[string]$Name
)
{
	$task = $BuildThis.Tasks[$Name]
	if (!$task) {
		ThrowTerminatingError "Task '$Name' is not defined." ObjectNotFound $Name
	}
	$task['Error']
}

<#
.Synopsis
	Checks for a condition.

.Description
	This function checks for a condition and throws a message if the condition
	is $false or not Boolean. In other words, the check succeeds if and only if
	the value is exactly $true.

	Assert-True has the predefined alias 'assert'.

.Parameter Condition
		The condition, exactly Boolean, in order to avoid subtle mistakes.

.Parameter Message
		A custom message to throw on condition check failures.

.Inputs
	None

.Outputs
	None
#>
function Assert-True
(
	[Parameter(Position = 0)]
	$Condition
	,
	[Parameter(Position = 1)]
	[string]$Message
)
{
	if ($Condition -isnot [bool]) {
		ThrowTerminatingError 'Condition is not Boolean.' InvalidArgument $Condition
	}

	if (!$Condition) {
		if ($Message) {
			ThrowTerminatingError $Message InvalidOperation
		}
		else {
			ThrowTerminatingError 'Assertion failed.' InvalidOperation
		}
	}
}

<#
.Synopsis
	Invokes the command and checks the $LastExitCode.

.Description
	The passed in command is supposed to call an executable tool. This function
	invokes the command and checks the $LastExitCode. By default if the code is
	not zero then the function throws a terminating error.

	It is common to call .NET framework tools. See Use-Framework.

	Invoke-Exec has the predefined alias 'exec'.

.Parameter Command
		The command that invokes an executable which exit code is checked.

.Parameter ExitCode
		Valid exit codes (e.g. 0..3 for robocopy). The default is @(0).

.Inputs
	None

.Outputs
	Outputs of the command and the tool that it invokes.

.Example
	# Call robocopy (0..3 are valid exit codes):
	exec { robocopy Source Target /mir } (0..3)

.Link
	Use-Framework
#>
function Invoke-Exec
(
	[Parameter(Position = 0, Mandatory = $true)]
	[scriptblock]$Command
	,
	[Parameter(Position = 1)]
	[ValidateNotNull()]
	[int[]]$ExitCode = @(0)
)
{
	${private:build-command} = $Command
	${private:build-valid} = $ExitCode
	Remove-Variable Command, ExitCode -Scope Local

	. ${private:build-command}

	if (${private:build-valid} -notcontains $LastExitCode) {
		ThrowTerminatingError "Command: {${private:build-command}}: last exit code is $LastExitCode." InvalidResult $LastExitCode
	}
}

<#
.Synopsis
	Sets framework tool aliases in the scope where it is called from.

.Description
	Invoke-Build does not change the system path in order to make framework
	tools available by names. This approach would be not suitable for using
	mixed framework tools simultaneously. Instead, this function is used in
	order to set framework aliases in the scope where it is called from.

	This function is often called once from a build script so that all tasks
	use script scope aliases. But it can be called from tasks as well in order
	to use more aliases or even use another framework.

.Parameter Framework
		The required framework directory relative to the Microsoft.NET in the
		Windows directory. If it is empty then the current runtime is used.

		Examples: Framework\v4.0.30319, Framework\v2.0.50727, etc.

.Parameter Tools
		The framework tool names to set aliases for and these alias names.

.Inputs
	None

.Outputs
	None

.Example
	# Use .NET 4.0 tools: MSBuild, csc, ngen. Then call MSBuild.
	Use-Framework Framework\v4.0.30319 MSBuild, csc, ngen
	exec { MSBuild Some.csproj /t:Build /p:Configuration=Release }

.Link
	Invoke-Exec
#>
function Use-Framework
(
	[Parameter()]
	[string]$Framework
	,
	[Parameter(Mandatory = $true)]
	[string[]]$Tools
)
{
	if ($PSCmdlet.MyInvocation.InvocationName -eq '.') {
		ThrowTerminatingError "Use-Framework should not be dot-sourced." InvalidOperation
	}

	if ($Framework) {
		$path = Join-Path "$env:windir\Microsoft.NET" $Framework
		if (![System.IO.Directory]::Exists($path)) {
			ThrowTerminatingError "Directory does not exist: '$path'." InvalidArgument $Framework
		}
	}
	else {
		$path = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
	}

	foreach($name in $Tools) {
		Set-Alias $name (Join-Path $path $name) -Scope 1
	}
}

<#
.Synopsis
	Outputs text as usual using colors if it makes sense for the output target.

.Description
	Unlike Write-Host this function also works for output redirected to a file.

.Parameter Color
		The [System.ConsoleColor] value or its string representation.

.Parameter Text
		Text to be printed using colors or just written to the output.

.Inputs
	None

.Outputs
	[string]
#>
function Write-Color
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

### End of the public zone. Exit if dot-sourced.
if ($PSCmdlet.MyInvocation.InvocationName -eq '.') {
	Write-Warning 'Dot-source Invoke-Build only in order to get help for its functions.'
	Get-Command Add-Task, Get-Error, Assert-True, Invoke-Exec, Use-Framework, Write-Color -ea 0 |
	Format-Table -AutoSize | Out-String
	return
}

# Use another Write-Color if there is no UI.
if (!$Host.UI -or !$Host.UI.RawUI) {
	function Write-Color
	(
		[Parameter()]
		[System.ConsoleColor]$Color
		,
		[Parameter()]
		[string]$Text
	)
	{
		$Text
	}
}

# Redefines Write-Warning to count messages
function Write-Warning([string]$Message)
{
	++$BuildInfo.WarningCount
	++$BuildThis.WarningCount
	Write-Color Yellow ("WARNING: " + $Message)
}

# Heals line breaks in the position message.
function Format-PositionMessage([string]$Message)
{
	$Message.Trim().Replace("`n", "`r`n")
}

# This command is used internally and should not be called directly.
# Build scripts should define standard functions shared between tasks.
function Invoke-Task($Name, $Path)
{
	# task object
	${private:build-task} = $BuildThis.Tasks[$Name]
	if (!${private:build-task}) { throw }

	# task path
	${private:build-path} = if ($Path) { "$Path\$Name" } else { $Name }

	# fail?
	if (${private:build-task}.ContainsKey('Error')) {
		Write-Color Yellow "${private:build-path} failed before."
	}
	# done?
	elseif (${private:build-task}.ContainsKey('Stopwatch')) {
		Write-Color DarkYellow "${private:build-path} was done before."
	}
	# skip?
	elseif (!${private:build-task}.If) {
	}
	# invoke
	else {
		++$BuildInfo.TaskCount
		++$BuildThis.TaskCount

		# hide variables
		Remove-Variable Name, Path -Scope Local

		${private:build-count} = ${private:build-task}.Jobs.Count
		${private:build-number} = 0

		${private:build-task}.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
		try {
			foreach(${private:build-job} in ${private:build-task}.Jobs) {
				++${private:build-number}
				if (${private:build-job} -is [string]) {
					try {
						Invoke-Task ${private:build-job} ${private:build-path}
					}
					catch {
						# try to survive
						if (${private:build-task}.Try -contains ${private:build-job}) {
							${private:build-why} = Test-TryTask ${private:build-job}
							if (${private:build-why}) {
								# die but tell why
								Write-Color Red ${private:build-why}
								throw
							}
							else {
								# survive but show the error
								${private:build-job} = $BuildThis.Tasks[${private:build-job}]
								if (!${private:build-job}) { throw }
								Write-Color Red (${private:build-job}.Error | Out-String)
							}
						}
						else {
							throw
						}
					}
				}
				elseif (${private:build-job} -is [scriptblock]) {
					# log any
					Write-Color DarkYellow "${private:build-path}[${private:build-number}/${private:build-count}]:"

					if ($WhatIf) {
						${private:build-job}
					}
					else {
						Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
						& ${private:build-job}

						# log 2+
						if (${private:build-task}.Jobs.Count -ge 2) {
							Write-Color DarkYellow "${private:build-path}[${private:build-number}/${private:build-count}] is done."
						}
					}
				}
			}
			Write-Color DarkYellow "${private:build-path} is done. $(${private:build-task}.Stopwatch.Elapsed)"
		}
		catch {
			++$BuildInfo.ErrorCount
			++$BuildThis.ErrorCount
			${private:build-task}.Error = $_
			Write-Color Yellow (Format-PositionMessage ${private:build-task}.Info.PositionMessage)

			throw
		}
		finally {
			${private:build-task}.Stopwatch.Stop()
		}
	}
}

# Try to find the reason why the try-task error is fatal.
function Test-TryTask([string]$TryTask)
{
	foreach($name in $BuildThis.Names) {
		$task = $BuildThis.Tasks[$name]
		if (!$task) { throw }
		$why = Test-TryTree $task $TryTask
		if ($why) {
			return $why
		}
	}
}

# Try to find the reason why the try-task error is fatal.
function Test-TryTree([object]$Task, [string]$TryTask)
{
	# ignored:
	if (!$Task.If) {
		return
	}

	# try-task is in jobs:
	if ($Task.Jobs -contains $TryTask) {
		# and it is not allowed to fail:
		if ($Task.Try -notcontains $TryTask) {
			"Task '$($Task.Name)' will fail due to '$TryTask'."
		}
		return
	}

	# jobs:
	foreach($job in $Task.Jobs) {
		if ($job -is [string]) {
			$task2 = $BuildThis.Tasks[$job]
			if (!$task2) { throw }
			$why = Test-TryTree $task2 $TryTask
			if ($why) {
				return $why
			}
		}
	}
}

# For internal use.
function Initialize-Task([object]$Task, [Collections.ArrayList]$Done)
{
	# ignore?
	if (!$Task.If) {
		Write-Color DarkGray "$($Task.Name) is excluded."
		return
	}

	# add the task to the list
	$count = 1 + $Done.Add($Task)

	# process task jobs
	$number = 0
	foreach($job in $Task.Jobs) {
		++$number
		if ($job -is [string]) {
			$task2 = $BuildThis.Tasks[$job]

			# missing:
			if (!$task2) {
				throw @"
Task '$($Task.Name)': Job $($number): Task '$job' is not defined.
$(Format-PositionMessage $Task.Info.PositionMessage)
"@
			}

			# ignore:
			if (!$task2.If) {
				continue
			}

			# cyclic:
			if ($Done.Contains($task2)) {
				throw @"
Task '$($Task.Name)': Job $($number): Cyclic reference to '$job'.
$(Format-PositionMessage $Task.Info.PositionMessage)
"@
			}

			# process job task
			Initialize-Task $task2 $Done
			$Done.RemoveRange($count, $Done.Count - $count)
		}
		elseif ($job -isnot [scriptblock]) {
			throw @"
Task '$($Task.Name)': Job $($number): Invalid job type.
$(Format-PositionMessage $Task.Info.PositionMessage)
"@
		}
	}
}

# Call it from advanced functions.
function ThrowTerminatingError($Message, $Category = 0, $Target)
{
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]$Message), $null, $Category, $Target))
}

### resolve the build
try {
	if ($Build) {
		${private:build-location} = Convert-Path (Resolve-Path -LiteralPath $Build -ErrorAction Stop)
	}
	else {
		${private:build-location} = @(Resolve-Path '*.build.ps1')
		if (!${private:build-location}) {
			throw "Found no '*.build.ps1' files."
		}
		if (${private:build-location}.Count -eq 1) {
			${private:build-location} = Convert-Path (${private:build-location}[0])
		}
		else {
			${private:build-location} = foreach($_ in ${private:build-location}) {
				if ([System.IO.Path]::GetFileName($_) -eq '.build.ps1') {
					Convert-Path $_
					break
				}
			}
			if (!${private:build-location}) {
				throw "Found more than one '*.build.ps1' and none of them is '.build.ps1'."
			}
		}
	}
}
catch {
	ThrowTerminatingError "$_" ObjectNotFound $Build
}

### set the variables
if (!(Test-Path Variable:\BuildInfo) -or ($BuildInfo -isnot [hashtable] -or ($BuildInfo['Id'] -ne '94abce897fdf4f18a806108b30f08c13'))) {
	New-Variable -Option Constant -Name BuildInfo -Value @{}
	$BuildInfo.Id = '94abce897fdf4f18a806108b30f08c13'
	$BuildInfo.TaskCount = 0
	$BuildInfo.ErrorCount = 0
	$BuildInfo.WarningCount = 0
	$BuildInfo.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
}
New-Variable -Option Constant -Name BuildFile -Value ${private:build-location}
New-Variable -Option Constant -Name BuildRoot -Value (Split-Path $BuildFile)
New-Variable -Option Constant -Name BuildThis -Value @{}
$BuildThis.Names = $Tasks
$BuildThis.Tasks = @{}
$BuildThis.TaskCount = 0
$BuildThis.ErrorCount = 0
$BuildThis.WarningCount = 0
$BuildThis.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
${private:build-location} = Get-Location

### hide variables
${private:build-tasks} = $Tasks
${private:94abce897fdf4f18a806108b30f08c13} = $Parameters
Remove-Variable Tasks, Build, Parameters -Scope Local

Write-Color DarkYellow "Build $(${private:build-tasks} -join ', ') from $BuildFile"
try {
	### invoke the build script (build loading)
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	. $BuildFile @94abce897fdf4f18a806108b30f08c13

	### show the tasks
	if (${private:build-tasks} -and ${private:build-tasks}[0] -eq '?') {
		$BuildThis.Tasks.Values | .{process{
			${private:build-task} = 1 | Select-Object Task, Info, File, Line
			${private:build-task}
			${private:build-task}.Task = $_.Name
			${private:build-file} = $_.Info.ScriptName
			${private:build-task}.File = ${private:build-file}
			${private:build-task}.Line = $_.Info.ScriptLineNumber
			if (${private:build-file} -like "$BuildRoot\*") {
				${private:build-file} = ${private:build-file}.Substring($BuildRoot.Length + 1)
			}
			${private:build-task}.Info = @"
$(($_.Jobs | %{ if ($_ -is [string]) { $_ } else { '{..}' } }) -join ', ') @ $(${private:build-file}):$(${private:build-task}.Line)
"@
		}} |
		Sort-Object File, Line |
		Format-Table Task, Info -AutoSize -Wrap
		return
	}

	### initialize the tasks (build preprocessing)
	foreach(${private:build-name} in ${private:build-tasks}) {
		${private:build-task} = $BuildThis.Tasks[${private:build-name}]
		if (!${private:build-task}) {
			ThrowTerminatingError "Task '${private:build-name}' is not defined." ObjectNotFound ${private:build-name}
		}
		Initialize-Task ${private:build-task} ([System.Collections.ArrayList]@())
	}

	### invoke the tasks (build processing)
	foreach(${private:build-name} in ${private:build-tasks}) {
		Invoke-Task ${private:build-name}
	}
	Write-Color DarkYellow @"
$($BuildThis.TaskCount) tasks, $($BuildThis.ErrorCount) errors, $($BuildThis.WarningCount) warnings, $($BuildThis.Stopwatch.Elapsed).
"@
}
finally {
	Set-Location -LiteralPath ${private:build-location} -ErrorAction Stop
	if ($($BuildInfo.TaskCount) -ne $($BuildThis.TaskCount)) {
		Write-Color DarkYellow @"
$($BuildInfo.TaskCount) tasks, $($BuildInfo.ErrorCount) errors, $($BuildInfo.WarningCount) warnings, $($BuildInfo.Stopwatch.Elapsed).
"@
	}
}
