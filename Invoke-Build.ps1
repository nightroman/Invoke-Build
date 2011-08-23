
<#
.Synopsis
	Invokes tasks from build scripts.
	v1.0.0.rc2 2011-08-23

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

	The idea is borrowed from the psake module and other similar build tools.
	The goal of this script is to provide a lightweight and yet robust engine.
	There is a number of cases and scenarios where this script works very well.

	The script is called directly with or without parameters, not dot-sourced.
	It is easier to use if it is located in one of the the system path folders.

	If the build script is not specified then Invoke-Build looks for the file
	".build.ps1" in the current location, then in the parent location tree.

	Tasks including imported from other scripts are invoked with the current
	location set to $BuildRoot which is the root of the main build script.
	Tasks may change locations and they do not have to care of restoring.

	EXPOSED FUNCTIONS

		* Add-Task
		* Out-Color
		* Invoke-Exec
		* Assert-True
		* Use-Framework

	EXPOSED ALIASES

		* task ~ Add-Task
		* exec ~ Invoke-Exec
		* assert ~ Assert-True

	EXPOSED VARIABLES

	Variables used by the Invoke-Build engine should not be visible for build
	scripts and tasks unless they are documented:

	Exposed variables designed for build scripts and tasks:

		* BuildFile - build script file path
		* BuildRoot - build script root path
		* WhatIf    - Invoke-Build parameter

	Variables for internal use but still visible:

		* BuildInfo - data for internal use
		* BuildList - list of registered tasks
		* PSCmdlet  - core variable of a caller

	HOW TO GET HELP

	This is a little bit tricky because:
	- the script is designed to work immediately even without parameters;
	- it should not be dot-sourced, do this once and only for getting help.

	Dot-source it with '?', ignore possible output, then get help as usual:

		PS> . Invoke-Build ?
		PS> help Use-Framework

.Parameter Tasks
		One or more tasks to be invoked. Use '?' in order to show tasks.

.Parameter Build
		The script with tasks defined by the Add-Task (alias task).

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
	# Invoke the 'default' task from the default .build.ps1 script:
	Invoke-Build

.Example
	# Show the tasks from the default .build.ps1 script and another script:
	Invoke-Build ?
	Invoke-Build ? Some.build.ps1

.Example
	# Invoke the specified tasks from the default script with parameters:
	Invoke-Build Task1, Task2 -Parameters @{ Param1 = 'Answer', Param2 = '42' }

.Link
	PS> . Invoke-Build ? # Then use Get-Help as usual.
	Add-Task
	Out-Color
	Invoke-Exec
	Assert-True
	Use-Framework
	https://github.com/nightroman/Invoke-Build
#>

param
(
	[Parameter()]
	[string[]]$Tasks = 'default'
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
	Adds the build task to the task list.

.Description
	This is the key function of build scripts. It creates build tasks, defines
	dependencies and invocation order, and adds the tasks to the internal list.

	Caution: Add-Task is called from build scripts (build preprocessing stage)
	but not from their tasks (build invocation stage).

	Add-Task has the predefined alias 'task'.

.Parameter Name
		The task name, any string except '?' ('?' is used to show tasks).

.Parameter Jobs
		The task jobs, existing task names and the task script block(s).

.Parameter If
		Tells whether to invoke the task ($true) or skip it ($false).
		The default is $true.

.Inputs
	None

.Outputs
	None
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
	$task = $BuildList[$Name]
	if ($task) {
		ThrowTerminatingError @"
Task '$Name' is added twice:
1: $(Format-PositionMessage $task.Info.PositionMessage)
2: $(Format-PositionMessage $MyInvocation.PositionMessage)
"@ InvalidOperation $Name
	}

	$BuildList.Add($Name, @{
		Name = $Name
		Jobs = $Jobs
		Info = $MyInvocation
		If = $If
	})
}

<#
.Synopsis
	Checks for a condition and throws a message if the condition is $false or not Boolean.

.Parameter Condition
		The condition, exactly Boolean, in order to avoid subtle mistakes.

.Parameter Message
		The message to throw on failure.

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
			ThrowTerminatingError 'Condition is $false.' InvalidOperation
		}
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
function Out-Color
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

# use another Out-Color if there is no UI
if (!$Host.UI -or !$Host.UI.RawUI) {
	function Out-Color
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

<#
.Synopsis
	Invokes the command and checks the $LastExitCode.

.Description
	The passed in command is supposed to call an executable tool. This function
	invokes the command and checks the $LastExitCode. By default if the code is
	not zero then the function throws an error showing the failed command.

	It is common to call .NET framework tools. Use the Use-Framework function.

	Invoke-Exec has the predefined alias 'exec'.

.Parameter Command
		The command which invokes an executable which exit code is checked.

.Parameter ExitCode
		Valid exit codes (e.g. 0..3 for robocopy).

.Inputs
	None

.Outputs
	Outputs of the Command and the tool that it calls.

.Example
	# Call robocopy
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
		ThrowTerminatingError "`$LastExitCode is $LastExitCode." InvalidResult $LastExitCode
	}
}

<#
.Synopsis
	Sets framework tool aliases and invokes a script with them.

.Description
	Invoke-Build does not change the system path in order to make framework
	tools available by names. This approach would be not suitable for using
	mixed framework tools simultaneously. Instead, this function is used in
	order to set framework aliases explicitly and invoke a script with them.

.Parameter Framework
		The required framework directory relative to the Microsoft.NET in the
		Windows directory. If it is empty then it is inferred from the current
		runtime.

		Examples: Framework\v4.0.30319, Framework\v2.0.50727, etc.

.Parameter Tools
		The framework tool names to set aliases for and also these alias names.

.Parameter Command
		The script block to be invoked with temporary framework tool aliases.

.Inputs
	None

.Outputs
	Outputs of the Command.

.Example
	# Call MSBuild 4.0 (exec is an alias of Invoke-Exec)
	Use-Framework Framework\v4.0.30319 MSBuild {
		exec { MSBuild Some.csproj /t:Build /p:Configuration=Release }
	}

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
	,
	[Parameter(Mandatory = $true)]
	[scriptblock]$Command
)
{
	if ($Framework) {
		${private:build-path} = Join-Path "$env:windir\Microsoft.NET" $Framework
		if (![System.IO.Directory]::Exists(${private:build-path})) {
			ThrowTerminatingError "Directory does not exist: '${private:build-path}'." ResourceUnavailable $Framework
		}
	}
	else {
		${private:build-path} = [Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
	}

	foreach(${private:build-tool} in $Tools) {
		Set-Alias ${private:build-tool} (Join-Path ${private:build-path} ${private:build-tool})
	}

	${private:build-command} = $Command
	Remove-Variable Framework, Tools, Command -Scope Local

	. ${private:build-command}
}

<#
.Synopsis
	Heals line breaks in the position message. Mostly for internal use.
#>
function Format-PositionMessage
(
	[string]$Message
)
{
	$Message.Trim().Replace("`n", "`r`n")
}

<#
.Synopsis
	For internal use. Invokes the build task.

.Description
	This command is used internally and should not be called directly.
	Build scripts should define standard functions shared between tasks.
#>
function Invoke-Task($Name, $Path)
{
	# task object
	${private:build-task} = $BuildList[$Name]
	Assert-True($null -ne ${private:build-task})

	# done?
	if (${private:build-task}.ContainsKey('Stopwatch')) {
	}
	# skip?
	elseif (!${private:build-task}.If) {
	}
	# invoke
	else {
		# hide variables
		${private:build-path} = "$Path\$Name"
		Remove-Variable Name, Path -Scope Local

		${private:build-count} = ${private:build-task}.Jobs.Count
		${private:build-number} = 0

		${private:build-task}.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
		foreach(${private:build-job} in ${private:build-task}.Jobs) {
			++${private:build-number}
			try {
				if (${private:build-job} -is [string]) {
					Invoke-Task ${private:build-job} ${private:build-path}
				}
				elseif (${private:build-job} -is [scriptblock]) {
					# log any
					Out-Color DarkYellow "${private:build-path}[${private:build-number}/${private:build-count}]:"

					if ($WhatIf) {
						${private:build-job}
					}
					else {
						Set-Location $BuildRoot
						& ${private:build-job}

						# log 2+
						if (${private:build-task}.Jobs.Count -ge 2) {
							Out-Color DarkYellow "${private:build-path}[${private:build-number}/${private:build-count}] is done."
						}
					}
				}
			}
			catch {
				Out-Color Yellow (Format-PositionMessage ${private:build-task}.Info.PositionMessage)
				++$BuildInfo.TaskErrorCount
				throw
			}
		}
		${private:build-task}.Stopwatch.Stop()

		Out-Color DarkYellow "${private:build-path} is done. $(${private:build-task}.Stopwatch.Elapsed)"
		++$BuildInfo.TaskBuiltCount
	}
}

# For internal use.
function Initialize-Task($Task, $Done)
{
	# ignore?
	if (!$Task.If) {
		Out-Color DarkGray "$($Task.Name) is ignored."
		return
	}

	# add the task to the current list
	${private:build-count} = 1 + $Done.Add($Task)

	# process task jobs
	${private:build-number} = 0
	foreach(${private:build-job} in $Task.Jobs) {
		++${private:build-number}
		if (${private:build-job} -is [string]) {
			${private:build-job-task} = $BuildList[${private:build-job}]

			# missing:
			if (!${private:build-job-task}) {
				throw @"
Task '$($Task.Name)': job $(${private:build-number}): task '${private:build-job}' is not defined.
$(Format-PositionMessage $Task.Info.PositionMessage)
"@
			}

			# ignore:
			if (!${private:build-job-task}.If) {
				continue
			}

			# cyclic:
			if ($Done.Contains(${private:build-job-task})) {
				throw @"
Task '$($Task.Name)': job $(${private:build-number}): cyclic reference to '${private:build-job}'.
$(Format-PositionMessage $Task.Info.PositionMessage)
"@
			}

			# process child task
			Initialize-Task ${private:build-job-task} $Done
			$Done.RemoveRange(${private:build-count}, $Done.Count - ${private:build-count})
		}
		elseif (${private:build-job} -isnot [scriptblock]) {
			throw @"
Task '$($Task.Name)': job $(${private:build-number}): invalid job type.
$(Format-PositionMessage $Task.Info.PositionMessage)
"@
		}
	}
}

# For internal use.
function Resolve-Build
{
	$build = '.build.ps1'
	if (!(Test-Path -LiteralPath $build)) {
		Write-Verbose "Default '$build' is not found."
		$location = Get-Location
		for(;;) {
			$location = Split-Path $location
			if (!$location) {
				return
			}
			$candidate = Join-Path $location $build
			Write-Verbose "Looking for '$candidate'"
			if (Test-Path -LiteralPath $candidate) {
				$build = $candidate
				break
			}
		}
	}
	Write-Verbose "Build script : $build"
	$build
}

# Call it from advanced functions.
function ThrowTerminatingError($Message, $Category, $Target)
{
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]$Message), $null, $Category, $Target))
}

### get the script
if (!$Build) {
	$Build = Resolve-Build
	if (!$Build) {
		if ($Tasks -and $Tasks[0] -eq '?') {
			return
		}
		ThrowTerminatingError "Cannot find the default build script in the parent tree."
	}
}

### set variables
${private:build-location} = Get-Location
New-Variable -Option Constant -Name BuildFile -Value (Resolve-Path -LiteralPath $Build)
New-Variable -Option Constant -Name BuildRoot -Value (Split-Path $Build)
New-Variable -Option Constant -Name BuildList -Value @{}

### hide variables
${private:build-tasks} = $Tasks
${private:_94abce897fdf4f18a806108b30f08c13} = $Parameters
Remove-Variable Tasks, Build, Parameters -Scope Local

Out-Color DarkYellow "Build $(${private:build-tasks} -join ', ') from $BuildFile"
try {
	### get the tasks
	Set-Location $BuildRoot
	. $BuildFile @_94abce897fdf4f18a806108b30f08c13

	### show the tasks
	if (${private:build-tasks} -and ${private:build-tasks}[0] -eq '?') {
		$BuildList.Values | .{process{
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

	### initialize the tasks (build preprocess)
	foreach(${private:build-name} in ${private:build-tasks}) {
		${private:build-task} = $BuildList[${private:build-name}]
		if (!${private:build-task}) {
			ThrowTerminatingError "Task '${private:build-name}' is not defined."
		}
		Initialize-Task ${private:build-task} ([System.Collections.ArrayList]@())
	}

	### get build info
	if (!(Test-Path Variable:\BuildInfo) -or ($BuildInfo -isnot [hashtable] -or ($BuildInfo['Id'] -ne '1a9384c8-d084-4dad-9db9-66505be49d74'))) {
		New-Variable -Option Constant -Name BuildInfo -Value @{}
		$BuildInfo.Id = '1a9384c8-d084-4dad-9db9-66505be49d74'
		$BuildInfo.TaskBuiltCount = 0
		$BuildInfo.TaskErrorCount = 0
	}

	### invoke the tasks (build process)
	${private:build-stopwatch} = [System.Diagnostics.Stopwatch]::StartNew()
	foreach(${private:build-name} in ${private:build-tasks}) {
		Invoke-Task ${private:build-name}
	}

	### total elapsed time
	if (${private:build-tasks}.Count -ge 2) {
		Out-Color DarkYellow ${private:build-stopwatch}.Elapsed
	}
}
finally {
	Set-Location ${private:build-location}
}
