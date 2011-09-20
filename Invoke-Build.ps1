
<#
.Synopsis
	Invoke-Build - Build Automation in PowerShell

.Description
	* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
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

	This script provides an easy to use and robust build engine with build
	scripts written in PowerShell and concepts similar to MSBuild and psake.

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
		* Get-BuildProperty (property)
		* Get-BuildVersion
		* Invoke-BuildExec (exec)
		* Start-Build [1]
		* Use-BuildAlias (use)
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
		The default task is "." if it exists otherwise the first added task.

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
	Get-BuildProperty
	Invoke-BuildExec
	Start-Build
	Use-BuildAlias
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
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias

<#
.Synopsis
	Gets Invoke-Build version.
#>
function Get-BuildVersion
{
	[System.Version]'1.0.15'
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
		* [string] - task jobs, existing task names;
		* [hashtable] - task jobs with options, @{TaskName = Option};
		* [scriptblock] - script jobs, script blocks invoked for this task.

		Notation @{TaskName = Option} references the task TaskName and assigns
		an Option to it. The only supported now option value is 1: protected
		task call. It tells to ignore task errors if other active tasks also
		call TaskName as protected.

.Parameter If
		Tells whether to invoke the task ($true) or skip it ($false). The
		default is $true. The value is either a script block evaluated on
		task invocation or a value treated as Boolean.

.Parameter Inputs
		File system items or literal paths used as input for full or partial
		incremental build, or a script which gets them. All input items must
		exist. All items are finally resolved to full paths and all or some of
		them (it depends on Outputs) are piped to the task script jobs.

		The script jobs are not invoked if all the Outputs are up-to-date or if
		the Inputs is not null and yet empty. But dependent tasks are invoked.

		Inputs and Outputs are processed on the first script job invocation.
		Thus, preceding task jobs can for example create the Inputs files.

.Parameter Outputs
		Literal output paths. There are two forms:

		1) [string] or [string[]] is for full incremental build. If there are
		missing items then the scripts are invoked. Otherwise they are invoked
		if the minimum output time is less than the maximum input time. All
		input paths are piped to the task scripts.
		* Automatic variables for script jobs:
		- [System.Collections.ArrayList]$Inputs - evaluated Inputs, full paths
		- $Outputs - exactly the Outputs value, i.e. [string] or [string[]]

		2) [scriptblock] is for partial incremental build. All input paths are
		piped to the Outputs script which gets exactly one path for each input.
		Then input and output time stamps are compared and only input paths
		with out-of-date output, if any, are piped to the task script jobs.
		* Automatic variables for script jobs:
		- [System.Collections.ArrayList]$Inputs - evaluated Inputs, full paths
		- [System.Collections.ArrayList]$Outputs - paths transformed by Outputs
		* In addition inside process{} blocks:
		- $_ - the current full input path
		- $$ - the current output path (returned by the Outputs script)

.Parameter After
		Tells to add this task to the specified task job lists. The task is
		added after the last script jobs, if any, otherwise to the end of job
		lists.

		Altered tasks are defined as names or constructs @{Task=1}. In the
		latter case this extra task is called protected (see the parameter
		Jobs).

		After and Before are used in order to alter build task jobs in special
		cases, normally when direct changes in task jobs are not suitable.

.Parameter Before
		Tells to add this task to the specified task job lists. It is added
		before the first script jobs, if any, otherwise to the end of the job
		lists. See the parameter After for details.

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
	[Parameter(Position = 1)]
	[object[]]$Jobs
	,
	[Parameter()]
	[object]$If = $true
	,
	[Parameter()]
	[object]$Inputs
	,
	[Parameter()]
	[object]$Outputs
	,
	[Parameter()]
	[object[]]$After
	,
	[Parameter()]
	[object[]]$Before
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

	if (($null -eq $Inputs) -ne ($null -eq $Outputs)) {
		Invoke-BuildError "Task '$Name': Inputs and Outputs should be both null or not null."
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

	$BuildThis.Tasks.Add($Name, @{
		Name = $Name
		Jobs = $jobList
		Try = $tryList
		If = $If
		Inputs = $Inputs
		Outputs = $Outputs
		After = $After
		Before = $Before
		Info = $MyInvocation
	})
}

<#
.Synopsis
	Gets an error of the specified task if the task has failed.

.Description
	This method is used when some dependent tasks are referenced as @{Task=1}
	(protected) and the current task script is about to analyse their errors.

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
	Gets PowerShell or environment variable value or the default value.

.Description
	A build property is a value of either PowerShell or environment variable.

	If the PowerShell variable with the specified name exists then its value is
	returned. Otherwise, if the environment variable with this name exists then
	its value is returned. Otherwise, the default value is returned or an error
	is thrown.

.Parameter Name
		PowerShell or environment variable name.

.Parameter Value
		Default value to be returned if the property is not found. Omitted or
		null value requires the specified property to be defined. If it is not
		then an error is thrown.

.Inputs
	None

.Outputs
	Requested property value.

.Example
	># Inherit the existing value or throw an error
	$OutputPath = property OutputPath

.Example
	># Get an existing value or use the default
	$WarningLevel = property WarningLevel 4
#>
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

<#
.Synopsis
	Checks for a condition.

.Description
	It checks for a condition and if it is not true throws a message.

	Assert-BuildTrue has the predefined alias 'assert'.

.Parameter Condition
		The condition.

.Parameter Message
		A user friendly message describing the assertion condition.

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
	if (!$Condition) {
		if ($Message) {
			Invoke-BuildError "Assertion failed: $Message" InvalidOperation
		}
		else {
			Invoke-BuildError 'Assertion failed.' InvalidOperation
		}
	}
}

<#
.Synopsis
	Invokes the command and checks for the $LastExitCode.

.Description
	The passed in command is supposed to call an executable tool. This function
	invokes the command and checks for the $LastExitCode. By default if the
	code is not zero then the function throws a terminating error.

	It is common to call .NET framework tools. See Use-BuildAlias.

	Invoke-BuildExec has the predefined alias 'exec'.

.Parameter Command
		The command that invokes an executable which exit code is checked.

.Parameter ExitCode
		Valid exit codes (e.g. 0..3 for robocopy). The default is 0.

.Inputs
	None

.Outputs
	Outputs of the command and the tool that it invokes.

.Example
	># Call robocopy (0..3 are valid exit codes):
	exec { robocopy Source Target /mir } (0..3)

.Link
	Use-BuildAlias
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
	${private:-command} = $Command
	${private:-valid} = $ExitCode
	Remove-Variable Command, ExitCode

	. ${private:-command}

	if (${private:-valid} -notcontains $LastExitCode) {
		Invoke-BuildError "Command: {${private:-command}}: Last exit code is $LastExitCode." InvalidResult $LastExitCode
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

	This function is often called from a build script and all tasks use script
	scope aliases. But it can be called from tasks in order to use more tools
	including other frameworks or tool directories.

.Parameter Path
		The tool directory. Null or empty assumes the current .NET runtime
		directory. If it starts with 'Framework' then it is assumed to be
		relative to Microsoft.NET in the Windows directory. Otherwise it is
		used literally, it can be any directory with any tools.

		Examples: Framework\v4.0.30319, Framework\v2.0.50727, C:\Scripts, etc.

.Parameter Name
		The tool names to set aliases for. These names also become alias names
		and they should be used exactly as specified.

.Inputs
	None

.Outputs
	None

.Example
	># Use .NET 4.0 tools MSBuild, csc, ngen. Then call MSBuild.
	use Framework\v4.0.30319 MSBuild, csc, ngen
	exec { MSBuild Some.csproj /t:Build /p:Configuration=Release }

.Link
	Invoke-BuildExec
#>
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
	[CmdletBinding()]param()

	if ($PSCmdlet.MyInvocation.InvocationName -ne '.') {
		Invoke-BuildError "Start-Build has to be dot-sourced." InvalidOperation
	}

	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') @ $BuildFile"
	try {
		${private:-tasks} = $BuildThis.Tasks

		### The first task
		if (!$BuildTask) {
			if (!${private:-tasks}.Count) {
				Invoke-BuildError "There is no task in the script."
			}
			if (${private:-tasks}.Contains('.')) {
				$BuildTask = '.'
			}
			else {
				$BuildTask = ${private:-tasks}.Item(0).Name
			}
		}

		### Alter task jobs
		foreach(${private:-task} in ${private:-tasks}.Values) {
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
			${private:-tasks}.Values | .{process{
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
		foreach(${private:-name} in $BuildTask) {
			${private:-task} = ${private:-tasks}[${private:-name}]
			if (!${private:-task}) {
				Invoke-BuildError "Task '${private:-name}' is not defined." ObjectNotFound ${private:-name}
			}
			Invoke-Build-Preprocess ${private:-task} ([System.Collections.ArrayList]@())
		}

		### Process tasks
		foreach(${private:-name} in $BuildTask) {
			Invoke-Build-Task ${private:-name}
		}

		### Summary
		$BuildThis.Messages
		if (($BuildThis.TaskCount -ge 2) -or ($BuildThis.ErrorCount) -or ($BuildThis.WarningCount)) {
			Invoke-Build-Write-Info $BuildThis
		}
	}
	finally {
		### Results
		Set-Location -LiteralPath ${private:-location} -ErrorAction Stop
		if (${private:-first} -and ($($BuildInfo.TaskCount) -ne $($BuildThis.TaskCount))) {
			$BuildInfo.Messages
			Invoke-Build-Write-Info $BuildInfo
		}
	}
}

# For advanced functions to show caller locations in errors.
function Invoke-BuildError($Message, $Category = 0, $Target)
{
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]$Message), $null, $Category, $Target))
}

### End of the public zone. Exit if dot-sourced from the command line.
${private:-sourced} = $PSCmdlet.MyInvocation.InvocationName -eq '.'
if (${private:-sourced}) {
	if (!$PSCmdlet.MyInvocation.ScriptName) {
		Write-Warning 'Invoke-Build is dot-sourced in order to get its command help.'
		Get-Command `
		task, Add-BuildTask, error, Get-BuildError, property, Get-BuildProperty,
		assert, Assert-BuildTrue, exec, Invoke-BuildExec, use, Use-BuildAlias,
		Get-BuildVersion, Write-BuildText, Start-Build | Format-Table -AutoSize | Out-String
		return
	}
	if ($BuildFile -or $Parameters) {
		Invoke-BuildError "Dot-sourced Invoke-Build does not accept BuildFile and Parameters." InvalidOperation
	}
	$BuildFile = $PSCmdlet.MyInvocation.ScriptName
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
	++$BuildThis.WarningCount
	$null = $BuildInfo.Messages.Add($Message)
	$null = $BuildThis.Messages.Add($Message)
}

# Adds the task to the referenced task jobs.
function Invoke-Build-Alter([string]$TaskName, $Refs, [switch]$After)
{
	foreach($ref in $Refs) {
		$name, $data = Invoke-Build-Reference $TaskName $ref

		$task = $BuildThis.Tasks[$name]
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
		throw "Task '$(${private:-task}.Name)': Error on resolving inputs: $_"
	}

	# no input:
	if (!${private:-paths}) {
		'Skipping because there is no input.'
		return
	}

	# evaluate outputs
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	if (${private:-task}.Outputs -is [scriptblock]) {
		${private:-task}.Partial = $true
		${private:-outputs} = @(${private:-paths} | & ${private:-task}.Outputs)
		if (${private:-paths}.Count -ne ${private:-outputs}.Count) {
			throw "Task '$(${private:-task}.Name)': Different input and output counts: $(${private:-paths}.Count) and $(${private:-outputs}.Count)."
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
		${private:-task}.Partial = $false
		${private:-task}.Inputs = ${private:-paths}

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
	${private:-task} = $BuildThis.Tasks[$Name]
	if (!${private:-task}) { throw }

	# the path, use the original name
	${private:-path} = if ($Path) { "$Path\$(${private:-task}.Name)" } else { ${private:-task}.Name }

	# 1) failed?
	if (${private:-task}.ContainsKey('Error')) {
		Write-BuildText Yellow "${private:-path} failed before."
		return
	}

	# 2) done?
	if (${private:-task}.ContainsKey('Stopwatch')) {
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

	# invoke
	++$BuildInfo.TaskCount
	++$BuildThis.TaskCount

	${private:-count} = ${private:-task}.Jobs.Count
	${private:-number} = 0
	${private:-do-input} = $true
	${private:-no-input} = $false

	${private:-task}.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
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
						${private:-job} = $BuildThis.Tasks[${private:-job}]
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
		Write-BuildText DarkYellow "${private:-path} is done, $(${private:-task}.Stopwatch.Elapsed)."
	}
	catch {
		++$BuildInfo.ErrorCount
		++$BuildThis.ErrorCount
		${private:-task}.Error = $_
		${private:-text} = "ERROR: Task ${private:-path}: $_"
		$null = $BuildInfo.Messages.Add(${private:-text})
		$null = $BuildThis.Messages.Add(${private:-text})
		Write-BuildText Yellow (Invoke-Build-Format-Message ${private:-task}.Info.PositionMessage)
		throw
	}
	finally {
		${private:-task}.Stopwatch.Stop()
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
	$task1 = $BuildThis.Tasks[$Task]
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
			$task2 = $BuildThis.Tasks[$job]

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

### Resolve the script
if (!${private:-sourced}) {
	try {
		if ($BuildFile) {
			${private:-location} = Resolve-Path -LiteralPath $BuildFile -ErrorAction Stop
		}
		else {
			${private:-location} = @(Resolve-Path '*.build.ps1')
			if (!${private:-location}) {
				throw "Found no '*.build.ps1' files."
			}
			if (${private:-location}.Count -eq 1) {
				${private:-location} = ${private:-location}[0]
			}
			else {
				${private:-location} = ${private:-location} -match '\\\.build\.ps1$'
				if (!${private:-location}) {
					throw "Found more than one '*.build.ps1' and none of them is '.build.ps1'."
				}
			}
		}
	}
	catch {
		Invoke-BuildError "$_" ObjectNotFound $BuildFile
	}
	$BuildFile = Convert-Path ${private:-location}
}

### Set the variables
${private:-first} = !(Test-Path Variable:\BuildInfo) -or ($BuildInfo -isnot [hashtable] -or ($BuildInfo['Id'] -ne '94abce897fdf4f18a806108b30f08c13'))
${private:-location} = Get-Location
if (${private:-first}) {
	New-Variable -Option Constant -Name BuildInfo -Value @{
		Id = '94abce897fdf4f18a806108b30f08c13'
		TaskCount = 0
		ErrorCount = 0
		WarningCount = 0
		Messages = [System.Collections.ArrayList]@()
		Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	}
}
New-Variable -Option Constant -Name BuildRoot -Value (Split-Path $BuildFile)
New-Variable -Option Constant -Name BuildThis -Value @{
	Tasks = [System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase)
	TaskCount = 0
	ErrorCount = 0
	WarningCount = 0
	Messages = [System.Collections.ArrayList]@()
	Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
}
${private:94abce897fdf4f18a806108b30f08c13} = $Parameters
Remove-Variable Parameters

### Invoke the script and tasks or just wait for tasks
Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
if (!${private:-sourced}) {
	if (${private:94abce897fdf4f18a806108b30f08c13}) {
		. $BuildFile @94abce897fdf4f18a806108b30f08c13
	} else {
		. $BuildFile
	}
	. Start-Build
}
