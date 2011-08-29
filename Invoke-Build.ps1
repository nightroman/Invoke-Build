
<#
.Synopsis
	Invoke-Build - Orchestrate Builds in PowerShell

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

	The ideas come from the psake module and a few other build and make tools.
	The goal of this script is to provide a very simple and yet robust engine.

	Installation: just copy Invoke-Build.ps1 to any directory of the $env:path.

	Build scripts may have one of two forms: "classic" scripts are called by
	Invoke-Build, "master" scripts dot-source Invoke-Build and Start-Build.

	Build scripts define parameters, variables, and tasks. Scripts and tasks
	are invoked with the current location set to the $BuildRoot which is the
	directory of the main build script.

	Dot-source Invoke-Build only in order to get help for its functions from
	the command line or in order to load the engine into master build scripts.

	EXPOSED FUNCTIONS AND ALIASES

		* Add-BuildTask (task)
		* Assert-BuildTrue (assert)
		* Get-BuildError (error)
		* Get-BuildVersion
		* Invoke-BuildExec (exec)
		* Start-Build [1]
		* Use-BuildFramework (framework)
		* Write-BuildText
		* Write-Warning [2]

	[1] Start-Build is called once from the end of a master build script.

	[2] Write-Warning is redefined internally in order to count warnings in
	tasks, build and other scripts. But warnings in modules are not counted.

	EXPOSED VARIABLES

	Only documented variables should be visible for build scripts and tasks.

	Exposed variables designed for build scripts and tasks:

		* BuildTask - invoked task names
		* BuildFile - build script file path
		* BuildRoot - build script root path
		* WhatIf    - Invoke-Build parameter

	Variables for internal use by Invoke-Build:

		* BuildInfo, BuildThis, PSCmdlet

.Parameter BuildTask
		One or more tasks to be invoked. Use '?' in order to view tasks.
		The default task is '.', just a dot.

.Parameter BuildFile
		The build script which defines build tasks by Add-BuildTask (task).

		If it is not specified then Invoke-Build looks for "*.build.ps1" files
		in the current location. A single file is used as the build script. If
		there are more files then ".build.ps1" is used as the default.

.Parameter Parameters
		The hashtable of parameters passed in the build script.

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
	># Invoke the default (.) task from the default build script:
	Invoke-Build

.Example
	># Show the tasks from the default build script and another script:
	Invoke-Build ?
	Invoke-Build ? Another.build.ps1

.Example
	># Invoke the specified tasks from the default script with parameters:
	Invoke-Build Task1, Task2 -Parameters @{ Param1 = 'Answer', Param2 = '42' }

.Link
	GitHub: https://github.com/nightroman/Invoke-Build
	Add-BuildTask
	Assert-BuildTrue
	Get-BuildError
	Invoke-BuildExec
	Start-Build
	Use-BuildFramework
	Write-BuildText
#>

param
(
	[Parameter(Position = 0)]
	[string[]]$BuildTask
	,
	[Parameter(Position = 1)]
	[string]$BuildFile
	,
	[Parameter(Position = 2)]
	[hashtable]$Parameters
	,
	[Parameter()]
	[switch]$WhatIf
)

### Predefined aliases
Set-Alias assert Assert-BuildTrue
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias framework Use-BuildFramework
Set-Alias task Add-BuildTask

<#
.Synopsis
	Gets the Invoke-Build version.
#>
function Get-BuildVersion
{
	[System.Version]'1.0.1'
}

<#
.Synopsis
	Adds the build task to the internal task list.

.Description
	This is the key function of build scripts. It creates build tasks, defines
	dependencies and invocation order, and adds the tasks to the internal list.

	Caution: Add-BuildTask is called from build scripts, not from their tasks.

	Add-BuildTask has the predefined alias 'task'.

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
		call TaskName as protected.

.Parameter If
		Tells whether to invoke the task ($true) or skip it ($false).
		The default is $true.

.Inputs
	None

.Outputs
	None

.Link
	Get-BuildError
#>
function Add-BuildTask
(
	[Parameter(Position = 0, Mandatory = $true)]
	[string]$Name
	,
	[Parameter(Position = 1, Mandatory = $true)]
	[object[]]$Jobs
	,
	[Parameter()]
	[bool]$If = $true
)
{
	$task = $BuildThis.Tasks[$Name]
	if ($task) {
		Invoke-BuildError @"
Task '$Name' is added twice:
1: $(Invoke-Build-Format-Message $task.Info.PositionMessage)
2: $(Invoke-Build-Format-Message $MyInvocation.PositionMessage)
"@ InvalidOperation $Name
	}

	$jobList = [System.Collections.ArrayList]@()
	$tryList = $null

	$index = -1
	foreach($job in $Jobs) {
		++$index
		if ($job -is [hashtable]) {
			if ($job.Count -ne 1) {
				Invoke-BuildError "Task '$Name': Job $($index + 1)/$($Jobs.Count): Hashtable should have one item." InvalidArgument $job
			}
			$string = @($job.Keys)[0]
			$null = $jobList.Add($string)
			if (@($job.Values)[0] -eq 1) {
				if ($tryList) {
					$null = $tryList.Add($string)
				}
				else {
					$tryList = [System.Collections.ArrayList]@($string)
				}
			}
		}
		elseif (($job -isnot [string]) -and($job -isnot [scriptblock])) {
			Invoke-BuildError "Task '$Name': Job $($index + 1)/$($Jobs.Count): Invalid job type." InvalidArgument $job
		}
		else {
			$null = $jobList.Add($job)
		}
	}

	$BuildThis.Tasks.Add($Name, @{
		Name = $Name
		Jobs = $jobList
		Try = $tryList
		If = $If
		Info = $MyInvocation
	})
}

<#
.Synopsis
	Gets an error of the specified task if the task has failed.

.Description
	This method is used when some task jobs are protected (@{ Task = 1 }) and
	the current task wants to analyse task errors.

.Parameter Task
		Name of the task which error is requested.

.Inputs
	None

.Outputs
	The error object or null if the task has no errors.

.Link
	Add-BuildTask
#>
function Get-BuildError
(
	[Parameter(Mandatory = $true)]
	[string]$Task
)
{
	$it = $BuildThis.Tasks[$Task]
	if (!$it) {
		Invoke-BuildError "Task '$Task' is not defined." ObjectNotFound $Task
	}
	$it['Error']
}

<#
.Synopsis
	Checks for a condition.

.Description
	This function checks for a condition and throws a message if the condition
	is $false or not Boolean. In other words, the check succeeds if and only if
	the value is exactly $true.

	Assert-BuildTrue has the predefined alias 'assert'.

.Parameter Condition
		The condition (exactly Boolean, in order to avoid subtle mistakes).

.Parameter Message
		A custom message to throw on condition check failures.

.Inputs
	None

.Outputs
	None
#>
function Assert-BuildTrue
(
	[Parameter()]
	$Condition
	,
	[Parameter()]
	[string]$Message
)
{
	if ($Condition -isnot [bool]) {
		Invoke-BuildError 'Condition is not Boolean.' InvalidArgument $Condition
	}

	if (!$Condition) {
		if ($Message) {
			Invoke-BuildError $Message InvalidOperation
		}
		else {
			Invoke-BuildError 'Assertion failed.' InvalidOperation
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

	It is common to call .NET framework tools. See Use-BuildFramework.

	Invoke-BuildExec has the predefined alias 'exec'.

.Parameter Command
		The command that invokes an executable which exit code is checked.

.Parameter ExitCode
		Valid exit codes (e.g. 0..3 for robocopy). The default is @(0).

.Inputs
	None

.Outputs
	Outputs of the command and the tool that it invokes.

.Example
	># Call robocopy (0..3 are valid exit codes):
	exec { robocopy Source Target /mir } (0..3)

.Link
	Use-BuildFramework
#>
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
	${private:build-command} = $Command
	${private:build-valid} = $ExitCode
	Remove-Variable Command, ExitCode -Scope Local

	. ${private:build-command}

	if (${private:build-valid} -notcontains $LastExitCode) {
		Invoke-BuildError "Command: {${private:build-command}}: last exit code is $LastExitCode." InvalidResult $LastExitCode
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
		The framework tool names to set aliases for. These names become alias
		names and should be using exactly as specified.

.Inputs
	None

.Outputs
	None

.Example
	># Use .NET 4.0 tools MSBuild, csc, ngen. Then call MSBuild.
	framework Framework\v4.0.30319 MSBuild, csc, ngen
	exec { MSBuild Some.csproj /t:Build /p:Configuration=Release }

.Link
	Invoke-BuildExec
#>
function Use-BuildFramework
(
	[Parameter()]
	[string]$Framework
	,
	[Parameter(Mandatory = $true)]
	[string[]]$Tools
)
{
	if ($PSCmdlet.MyInvocation.InvocationName -eq '.') {
		Invoke-BuildError "Use-BuildFramework should not be dot-sourced." InvalidOperation
	}

	if ($Framework) {
		$path = Join-Path "$env:windir\Microsoft.NET" $Framework
		if (![System.IO.Directory]::Exists($path)) {
			Invoke-BuildError "Directory does not exist: '$path'." InvalidArgument $Framework
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
	Writes text using colors (if this makes sense for the output target).

.Description
	Unlike Write-Host this function is suitable for output sent to a file.

.Parameter Color
		The [System.ConsoleColor] value or its string representation.

.Parameter Text
		Text to be printed using colors or just sent to the output.

.Inputs
	None

.Outputs
	[string]
#>
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

<#
.Synopsis
	Starts building after adding tasks in a master build script.

.Description
	The function is called from "master" build scripts, normally as the last
	command. In contrast to "classic" scripts master scripts are invoked
	directly as regular scripts, not by Invoke-Build.

	The advantage of master scripts is that they are much easier to call. This
	is especially true when they have a lot of parameters. The price is quite
	low, just a couple of dot-sourced calls in the beginning and the end.

	Master scripts call . Invoke-Build, add tasks, then call . Start-Build.

	Invoke-Build sets the current location to a build script directory. This is
	also done on every task invocation. The old location is restored when
	Start-Build is completed.

	A trivial master script without own parameters looks like this:

		# Script Build.ps1

		. Invoke-Build $args
		task task1 ...
		task task2 ...
		. Start-Build

	Such a script is invoked with task arguments:

		.\Build.ps1 ?
		.\Build.ps1 task1
		.\Build.ps1 task1 task2

	A more realistic master script with own parameters:

		# Script Build.ps1

		param
		(
			[string[]]$BuildTask, # to be passed in Invoke-Build
			[...]$Parameter1,     # own script parameter 1
			[...]$Parameter2,     # own script parameter 2
			...
			[switch]$WhatIf       # Invoke-Build option
		)

		. Invoke-Build $BuildTask -WhatIf:$WhatIf
		task task1 ...
		task task2 ...
		. Start-Build

	It is invoked with task names and parameters as a regular script:

		.\Build.ps1 ?
		.\Build.ps1 task1, task2 'Answer' 42
		.\Build.ps1 task2 -Parameter2 42 -WhatIf

.Inputs
	None

.Outputs
	Build process messages, diagnostics, warnings, errors, etc.

.Link
	Invoke-Build
#>
function Start-Build
{
	# no parameters
	[CmdletBinding()]param()

	if ($PSCmdlet.MyInvocation.InvocationName -ne '.') {
		Invoke-BuildError "Start-Build has to be dot-sourced." InvalidOperation
	}

	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') @ $BuildFile"
	try {
		### View the tasks
		if ($BuildTask[0] -eq '?') {
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

		### Initialize (build preprocessing)
		foreach(${private:build-name} in $BuildTask) {
			${private:build-task} = $BuildThis.Tasks[${private:build-name}]
			if (!${private:build-task}) {
				Invoke-BuildError "Task '${private:build-name}' is not defined." ObjectNotFound ${private:build-name}
			}
			Invoke-Build-Initialize-Task ${private:build-task} ([System.Collections.ArrayList]@())
		}

		### Invoke the tasks (build processing)
		foreach(${private:build-name} in $BuildTask) {
			Invoke-Build-Task ${private:build-name}
		}
		if (($BuildThis.TaskCount -ge 2) -or ($BuildThis.ErrorCount) -or ($BuildThis.WarningCount)) {
			Invoke-Build-Write-Info $BuildThis
		}
	}
	finally {
		Set-Location -LiteralPath ${private:build-location} -ErrorAction Stop
		$BuildInfo.Messages
		if (${private:build-first} -and ($($BuildInfo.TaskCount) -ne $($BuildThis.TaskCount))) {
			Invoke-Build-Write-Info $BuildInfo
		}
	}
}

# For advanced functions to show the caller error location.
function Invoke-BuildError($Message, $Category = 0, $Target)
{
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]$Message), $null, $Category, $Target))
}

### End of the public zone. Exit if dot-sourced.
${private:build-sourced} = $PSCmdlet.MyInvocation.InvocationName -eq '.'
if (${private:build-sourced}) {
	if (!$PSCmdlet.MyInvocation.ScriptName) {
		Write-Warning 'Invoke-Build is dot-sourced in order to get help for its functions.'
		Get-Command Add-BuildTask, Get-BuildError, Assert-BuildTrue, Invoke-BuildExec, Use-BuildFramework, Write-BuildText, Build -ea 0 |
		Format-Table -AutoSize | Out-String
		return
	}
	if ($BuildFile -or $Parameters) {
		Invoke-BuildError "Dot-sourced Invoke-Build does not allow parameters BuildFile and Parameters." InvalidOperation
	}
	$BuildFile = $PSCmdlet.MyInvocation.ScriptName
}

# Use another Write-BuildText if there is no UI.
if (!$Host.UI -or !$Host.UI.RawUI) {
	function Write-BuildText
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

# Redefines Write-Warning to collect warning messages.
function Write-Warning([string]$Message)
{
	$Message = "WARNING: " + $Message
	Write-BuildText Yellow $Message
	++$BuildInfo.WarningCount
	++$BuildThis.WarningCount
	$null = $BuildInfo.Messages.Add($Message)
}

# Heals line breaks in the position message.
function Invoke-Build-Format-Message([string]$Message)
{
	$Message.Trim().Replace("`n", "`r`n")
}

# This command is used internally and should not be called directly.
# Build scripts should define standard functions shared between tasks.
function Invoke-Build-Task($Name, $Path)
{
	# task object
	${private:build-task} = $BuildThis.Tasks[$Name]
	if (!${private:build-task}) { throw }

	# task path
	${private:build-path} = if ($Path) { "$Path\$Name" } else { $Name }

	# fail?
	if (${private:build-task}.ContainsKey('Error')) {
		Write-BuildText Yellow "${private:build-path} failed before."
	}
	# done?
	elseif (${private:build-task}.ContainsKey('Stopwatch')) {
		Write-BuildText DarkYellow "${private:build-path} was done before."
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
						Invoke-Build-Task ${private:build-job} ${private:build-path}
					}
					catch {
						# die if the task is not protected
						if (${private:build-task}.Try -notcontains ${private:build-job}) {
							throw
						}
						# try to survive
						${private:build-why} = Invoke-Build-Approve-Task ${private:build-job}
						if (${private:build-why}) {
							# tell why and die
							Write-BuildText Red ${private:build-why}
							throw
						}
						else {
							# show the error and survive
							${private:build-job} = $BuildThis.Tasks[${private:build-job}]
							if (!${private:build-job}) { throw }
							Write-BuildText Red (${private:build-job}.Error | Out-String)
						}
					}
				}
				elseif (${private:build-job} -is [scriptblock]) {
					${private:build-title} = "${private:build-path} (${private:build-number}/${private:build-count})"
					Write-BuildText DarkYellow "${private:build-title}:"

					if ($WhatIf) {
						${private:build-job}
					}
					else {
						Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
						& ${private:build-job}

						if (${private:build-task}.Jobs.Count -ge 2) {
							Write-BuildText DarkYellow "${private:build-title} is done."
						}
					}
				}
			}
			Write-BuildText DarkYellow "${private:build-path} is done, $(${private:build-task}.Stopwatch.Elapsed)."
		}
		catch {
			++$BuildInfo.ErrorCount
			++$BuildThis.ErrorCount
			${private:build-task}.Error = $_
			$null = $BuildInfo.Messages.Add("ERROR: Task ${private:build-path}: $_")
			Write-BuildText Yellow (Invoke-Build-Format-Message ${private:build-task}.Info.PositionMessage)
			throw
		}
		finally {
			${private:build-task}.Stopwatch.Stop()
		}
	}
}

# Gets null to survive or a reason to die on protected task errors.
function Invoke-Build-Approve-Task([string]$TryTask)
{
	foreach($name in $BuildTask) {
		$task = $BuildThis.Tasks[$name]
		if (!$task) { throw }
		$why = Invoke-Build-Approve-Tree $task $TryTask
		if ($why) {
			return $why
		}
	}
}

# Gets null to survive or a reason to die on protected task errors.
function Invoke-Build-Approve-Tree([object]$Task, [string]$TryTask)
{
	# ignored:
	if (!$Task.If) {
		return
	}

	# try-task is in jobs:
	if ($Task.Jobs -contains $TryTask) {
		# and it is not protected
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
			$why = Invoke-Build-Approve-Tree $task2 $TryTask
			if ($why) {
				return $why
			}
		}
	}
}

# Preprocessing of a task.
function Invoke-Build-Initialize-Task([object]$Task, [Collections.ArrayList]$Done)
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
			$task2 = $BuildThis.Tasks[$job]

			# missing:
			if (!$task2) {
				throw @"
Task '$($Task.Name)': Job $($number): Task '$job' is not defined.
$(Invoke-Build-Format-Message $Task.Info.PositionMessage)
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
$(Invoke-Build-Format-Message $Task.Info.PositionMessage)
"@
			}

			# process job task
			Invoke-Build-Initialize-Task $task2 $Done
			$Done.RemoveRange($count, $Done.Count - $count)
		}
	}
}

# Writes build information.
function Invoke-Build-Write-Info([hashtable]$Info)
{
	if ($Info.ErrorCount) {
		$color = 'Red'
	}
	elseif ($Info.WarningCount) {
		$color = 'Yellow'
	}
	else {
		$color = 'Green'
	}
	Write-BuildText $color @"
$($Info.TaskCount) tasks, $($Info.ErrorCount) errors, $($Info.WarningCount) warnings, $($Info.Stopwatch.Elapsed).
"@
}

### Resolve the file
if (!${private:build-sourced}) {
	try {
		if ($BuildFile) {
			${private:build-location} = Resolve-Path -LiteralPath $BuildFile -ErrorAction Stop
		}
		else {
			${private:build-location} = @(Resolve-Path '*.build.ps1')
			if (!${private:build-location}) {
				throw "Found no '*.build.ps1' files."
			}
			if (${private:build-location}.Count -eq 1) {
				${private:build-location} = ${private:build-location}[0]
			}
			else {
				${private:build-location} = ${private:build-location} -match '\\\.build\.ps1$'
				if (!${private:build-location}) {
					throw "Found more than one '*.build.ps1' and none of them is '.build.ps1'."
				}
			}
		}
	}
	catch {
		Invoke-BuildError "$_" ObjectNotFound $BuildFile
	}
	$BuildFile = Convert-Path ${private:build-location}
}

### Set the variables
${private:build-location} = Get-Location
${private:build-first} = !(Test-Path Variable:\BuildInfo) -or ($BuildInfo -isnot [hashtable] -or ($BuildInfo['Id'] -ne '94abce897fdf4f18a806108b30f08c13'))
if (${private:build-first}) {
	New-Variable -Option Constant -Name BuildInfo -Value @{}
	$BuildInfo.Id = '94abce897fdf4f18a806108b30f08c13'
	$BuildInfo.TaskCount = 0
	$BuildInfo.ErrorCount = 0
	$BuildInfo.WarningCount = 0
	$BuildInfo.Messages = [System.Collections.ArrayList]@()
	$BuildInfo.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
}
if (!$BuildTask) { $BuildTask = @('.') }
Set-Variable -Option ReadOnly -Name BuildTask
Set-Variable -Option ReadOnly -Name BuildFile
New-Variable -Option Constant -Name BuildRoot -Value (Split-Path $BuildFile)
New-Variable -Option Constant -Name BuildThis -Value @{}
$BuildThis.Tasks = @{}
$BuildThis.TaskCount = 0
$BuildThis.ErrorCount = 0
$BuildThis.WarningCount = 0
$BuildThis.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

### Hide variables
${private:94abce897fdf4f18a806108b30f08c13} = $Parameters
Remove-Variable Parameters -Scope Local

### Set location to the build root
Set-Location -LiteralPath $BuildRoot -ErrorAction Stop

### Invoke the file and tasks
if (!${private:build-sourced}) {
	. $BuildFile @94abce897fdf4f18a806108b30f08c13
	. Start-Build
}
