
<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

### Invoke-Build.ps1
@{
	command = 'Invoke-Build.ps1'
	synopsis = 'Invoke-Build - PowerShell Task Scripting'
	description = @'
	Install: copy Invoke-Build.ps1 and Invoke-Build.ps1-Help.xml to the path.

	This script invokes specified tasks defined in a PowerShell script. This
	process is called build and its concepts are similar to MSBuild and psake.

	A build script defines parameters, variables, tasks, and events. Any code
	is invoked with the current location set to $BuildRoot, the build script
	directory. $ErrorActionPreference is set to 'Stop'.

	In order to get help for functions used in scripts invoke Invoke-Build.ps1
	by the operator . and then use Get-Help:

		PS> . Invoke-Build.ps1  # shows available function names
		PS> Get-Help <function> # help for one of the functions

	EXPOSED FUNCTIONS AND ALIASES

		* Add-BuildTask (task)
		* Assert-Build (assert)
		* Get-BuildError (error)
		* Get-BuildProperty (property)
		* Get-BuildVersion
		* Invoke-BuildExec (exec)
		* Use-BuildAlias (use)
		* Write-Build
		* Write-Warning [1]
		* Get-BuildFile [2]

	[1] Write-Warning is redefined internally in order to count warnings in
	tasks, build and other scripts. But warnings in modules are not counted.

	[2] Exposed for Get-BuildFileHook.

	SPECIAL ALIASES

		* Invoke-Build
		* Invoke-Builds

	These aliases are for the scripts Invoke-Build.ps1 and Invoke-Builds.ps1.
	Use them for calling nested builds, i.e. omit script extensions and paths.
	With this rule Invoke-Build tools can be kept together with build scripts.

	EXPOSED VARIABLES

	Only documented variables should be visible for build scripts and tasks.

	Exposed variables designed for build scripts and tasks:

		$WhatIf    - WhatIf mode, Invoke-Build parameter
		$BuildRoot - build script location
		$BuildFile - build script path
		$BuildTask - initial tasks

	Variable for internal use by the engine:

		${*}

	NOTE: The special variable $_ can be defined and visible. Scripts and tasks
	can use it as their own, that is assign at first. Only in special cases it
	can be used as an input without assignment.

	EVENT FUNCTIONS

	The build engine defines and calls the following empty functions:

		* Enter-Build     - before the first task
		* Enter-BuildTask - before each task
		* Enter-BuildJob  - before each job
		* Exit-Build      - after the last task
		* Exit-BuildTask  - after each task
		* Exit-BuildJob   - after each job
		* Export-Build    - after each task of a persistent build
		* Import-Build    - once on resuming of a persistent build

	A script can redefine them. Note that nested builds do not inherit events,
	the engine always defines new empty functions before invoking a new script.

	Events are not called on WhatIf. If Enter-* is called then its pair Exit-*
	is called, too. Events are suitable for initializing and cleaning things.

	Enter-Build and Exit-Build are invoked in the script scope. Enter-Build is
	a good place for heavy initialization, it does not have to care of WhatIf.

	Enter-BuildTask and Exit-BuildTask are invoked in the same new scope which
	is the parent for a task invoked between them. The task object is passed in
	as the single argument. The following task properties are available for
	reading in both functions:

		* Name - task name, [string]
		* Started - start time, [DateTime]

	Exit-BuildTask may read two extra properties:

		* Error - error that stopped the task
		* Elapsed - task duration, [TimeSpan]

	Enter-BuildJob and Exit-BuildJob are invoked in the same scope as
	*-BuildTask and take two arguments - the task and the job number.

	Export-Build and Import-Build are used with persistent builds. Export-Build
	outputs data to be exported to clixml. Import-Build is called with a single
	argument containing the original data imported from clixml. It is called in
	the script scope and normally restores script scope variables.
'@
	parameters = @{
		Task = @'
		One or more tasks to be invoked. If it is not specified, null, empty,
		or equal to '.' then the task '.' is invoked if it exists, otherwise
		the first added task is invoked.

		NOTE: Names with wildcard characters are reserved for special tasks.

		SPECIAL TASKS

		* - Tells to invoke all root tasks. This is useful for scripts where
		each task tests something. Such test tasks are often invoked together.

		? - Tells to list the tasks with brief information without invoking. It
		also checks tasks and throws errors on missing or cyclic references. If
		it is used together with Result then tasks are returned as the property
		All of the result object. ? sets WhatIf to $true.
'@
		File = @'
		A build script which defines build tasks by Add-BuildTask (task).

		If it is not specified then Invoke-Build looks for "*.build.ps1" files
		in the current location. A single file is used as the script. If there
		are more files then ".build.ps1" is used.

		If the file is not found the command Get-BuildFileHook is called if it
		exists. It gets full path of an existing build file for the current
		location, e.g. when it is not suitable to have a build file there.
'@
		Parameters = @'
		A hashtable of parameters passed in the build script. Scripts define
		parameters as usual using standard PowerShell syntax. Parameters are
		available for all tasks: for reading simply as $ParameterName, for
		writing as $script:ParameterName. This is true as well for other
		variables defined in the script scope.
'@
		Checkpoint = @'
		Specifies the checkpoint file and makes the build persistent. It is
		possible to resume an interrupted build starting at an interrupted
		task. The checkpoint file is deleted on successful builds.

		In order to start a persistent build also use one of the Task, File,
		and Parameters, even with default values. In order to resume a build
		the Checkpoint should be used alone. Task, File, and Parameters are
		restored from the checkpoint file.

		Persistent builds must be designed properly. Data shared by tasks are
		exported and imported by the functions Export-Build and Import-Build.
		Trivial script parameters normally do not have to be serialized.

		NOTE: Some data are not suitable for clixml serialization.
'@
		Result = @'
		Tells to output build information using a variable. It is either a name
		of variable to be created or any object with the property Value to be
		assigned (e.g. a [ref] or [hashtable]).

		If the Task is ? then the build script is invoked in WhatIf mode, tasks
		are checked for missing and cyclic references and returned object as
		the property All.

		Otherwise tasks are invoked and the variable contains build results.

		Result object properties:
		* All - all defined tasks
		* Error - a terminating build error
		* Tasks - invoked tasks including nested
		* Errors - error messages including nested
		* Warnings - warning messages including nested

		Task object properties:
		* Name - task name
		* Error - task error
		* Started - start time
		* Elapsed - task duration
		* InvocationInfo.ScriptName, .ScriptLineNumber - task location.

		Other result and task data should not be used. These data should not be
		changed, especially if they are requested for a nested build, parent
		builds use these data.
'@
		Safe = @'
		Tells to catch a build failure, store an error as the property Error of
		Result and return quietly. A caller should use Result and check its
		Error in order to analyse build failures.

		NOTE: Some exceptions are possible even in safe mode. They show serious
		errors, not build failures. For example, a build script is missing.

		NOTE: Errors thrown in normal mode and errors stored in safe mode are
		often but not always the same. Some thrown errors are enhanced caught
		errors. Stored errors are exactly caught errors.
'@
		WhatIf = @'
		Tells to show preprocessed tasks and their scripts instead of invoking
		them. If a script does anything but adding and configuring tasks then
		it may check for $WhatIf and skip some actions.
'@
	}
	inputs = @()
	outputs = @(
		@{
			type = 'Text'
			description = @'
		Build process diagnostics, warning, and error messages, and output of
		scripts, tasks, and commands that they invoke.
'@
		}
	)
	examples = @(
		@{
			code = {
	# Invoke the default task in the default script:
	Invoke-Build
	Invoke-Build .
			}
		}
		@{
			code = {
	# Invoke the specified tasks and script with parameters
	# (the script .build.ps1 defines parameters by 'param', as usual)
	Invoke-Build Build, Test .build.ps1 @{Log='log.txt'; WarningLevel=4 }
			}
		}
		@{
			code = {
	# Show the tasks in the default script and the specified script:
	Invoke-Build ?
	Invoke-Build ? Project.build.ps1
			}
		}
		@{
			code = {
	# Get the tasks without invoking (for listing, TabExpansion, etc.)
	Invoke-Build ? -Result Tasks
	$Tasks
			}
		}
		@{
			code = {
	# Using the the build results (e.g. performance analysis)

	# Invoke the build and keep results in the variable Result
	Invoke-Build -Result Result

	# Show invoked tasks ordered by Elapsed with ScriptName included
	$Result.Tasks |
	Sort-Object Elapsed |
	Format-Table -AutoSize Elapsed, @{
		Name = 'Task'
		Expression = {$_.Name + ' @ ' + $_.InvocationInfo.ScriptName}
	}
			}
		}
		@{
			code = {
	# Using the the build results (e.g. tasks summary)

	try {
		# Invoke the build and keep results in the variable Result
		Invoke-Build -Result Result
	}
	finally {
		# Show task summary information after the build
		$result.Tasks | Format-Table Elapsed, Name, Error -AutoSize
	}
			}
		}
	)
	links = @(
		@{ text = 'Wiki'; URI = 'https://github.com/nightroman/Invoke-Build/wiki' }
		@{ text = 'Project'; URI = 'https://github.com/nightroman/Invoke-Build' }
		@{ text = 'Add-BuildTask' }
		@{ text = 'Assert-Build' }
		@{ text = 'Get-BuildError' }
		@{ text = 'Get-BuildProperty' }
		@{ text = 'Invoke-BuildExec' }
		@{ text = 'Use-BuildAlias' }
		@{ text = 'Write-Build' }
	)
}

### Add-BuildTask
@{
	command = 'Add-BuildTask'
	synopsis = 'Defines a build task and adds it to the internal task list.'
	description = @'
	Its recommended alias is 'task'. This is the main feature of build scripts.
	At least one task must be added. It is used in the build script scope only.

	In fact, this feature is literally all that build scripts really need.
	Other build functions are just helpers, scripts do not have to use them.
'@
	parameters = @{
		Name = @'
		The task name. Wildcard characters are deprecated. Duplicated names are
		allowed, each added task overrides previously added with the same name.
'@
		Jobs = @'
		One or more task jobs. Valid job types are:
		* [string] - name of an existing referenced task;
		* [hashtable] - referenced task with options, @{TaskName = Option};
		* [scriptblock] - script job, a script block invoked for this task.

		Notation @{TaskName = Option} assigns an option to the referenced task.
		The only supported option 1 makes a task reference protected. It tells
		to ignore task errors if other tasks also reference TaskName protected.
'@
		After = @'
		Tells to add this task to the end of the specified task job lists.

		Altered tasks are defined as names or constructs @{Task = 1}. In the
		latter case this task is called protected, see Jobs for details.

		Parameters After and Before are used in order to alter build task jobs
		in special cases when direct changes in task jobs are not suitable.
'@
		Before = @'
		Tells to add this task to job lists of the specified tasks. It is
		inserted before the first script job, if any, or added to the end.

		See the parameter After for details.
'@
		If = @'
		Tells whether to invoke the task ($true) or skip it ($false). The
		default is $true. The value is either a script block evaluated on task
		invocation or any value treated as Boolean. In WhatIf mode a
		scriptblock treated as $true without invocation.

		If it is a script block and the task is called several times then it is
		possible that the task is at first skipped but still invoked later when
		this block gets true.
'@
		Inputs = @'
		Tells to process the task as incremental and requires the parameter
		Outputs with the optional switch Partial.

		Inputs are file items or paths or a script block which gets them.
		Outputs are file paths or a script block which gets them.

		Automatic variables for task script jobs:
		* $Inputs - full input paths, array of strings
		* $Outputs - result of the evaluated parameter Outputs

		With the switch Partial the task is processed as partial incremental.
		There must be one-to-one correspondence between Inputs and Outputs.

		Partial Outputs are file paths or a script block which is invoked with
		input paths piped to it in order to transform them into output paths.

		In addition to automatic variables $Inputs and $Outputs, inside
		process{} blocks of a partial task two more variables are defined:
		* $_ - current full input path
		* $2 - current output path

		Wiki about incremental and partial incremental tasks:
		https://github.com/nightroman/Invoke-Build/wiki/Incremental-Tasks
		https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks
'@
		Outputs = @'
		Specifies the output paths of the incremental task. It is used together
		with Inputs. See Inputs for details.
'@
		Partial = @'
		Tells to process the incremental task as partial incremental. It is
		used together with Inputs and Outputs. See Inputs for details.
'@
	}
	inputs = @()
	outputs = @()
	links = @(
		@{ text = 'Get-BuildError' }
		@{ URI = 'https://github.com/nightroman/Invoke-Build/wiki/Script-Tutorial' }
		@{ URI = 'https://github.com/nightroman/Invoke-Build/wiki/Incremental-Tasks' }
		@{ URI = 'https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks' }
	)
}

### Get-BuildError
@{
	command = 'Get-BuildError'
	synopsis = 'Gets an error of the specified task if the task has failed.'
	description = @'
	Its recommended alias is 'error'. It is used when some referenced tasks are
	protected (@{Task=1}) and the current task is about to analyse their
	potential errors.
'@
	parameters = @{
		Task = @'
		Name of the task which error is requested.
'@
	}
	inputs = @()
	outputs = @(
		@{
			type = 'Error'
			description = @'
		The error object or null if the task has no errors.
'@
		}
	)
	links = @(
		@{ text = 'Add-BuildTask' }
	)
}

### Assert-Build
@{
	command = 'Assert-Build'
	synopsis = 'Checks for a condition.'
	description = @'
	Its recommended alias is 'assert'. It checks for a condition and if it is
	not true throws an error with an optional message text.
'@
	parameters = @{
		Condition = @'
		The condition.
'@
		Message = @'
		A user friendly message describing the assertion condition.
'@
	}
	inputs = @()
	outputs = @()
}

### Get-BuildProperty
@{
	command = 'Get-BuildProperty'
	synopsis = 'Gets PowerShell or environment variable or the default.'
	description = @'
	Its recommended alias is 'property'. It gets the first not null value of
	these three: PowerShell variable, environment variable, specified default
	value. Otherwise an error is thrown.

	CAUTION: Properties should be used sparingly with carefully chosen names
	that unlikely can already exist and be not related to the build script.
'@
	parameters = @{
		Name = @'
		PowerShell or environment variable name.
'@
		Value = @'
		Default value to be returned if the property is not found. Omitted or
		null value requires the specified property to be defined. If it is not
		then an error is thrown.
'@
	}
	inputs = @()
	outputs = @(
		@{
			type = 'Object'
			description = @'
		Requested property value.
'@
		}
	)
	examples = @(
		@{
			code = {
	# Inherit the existing value or throw an error
	$OutputPath = property OutputPath
			}
		}
		@{
			code = {
	# Get an existing value or use the default
	$WarningLevel = property WarningLevel 4
			}
		}
	)
}

### Get-BuildVersion
@{
	command = 'Get-BuildVersion'
	synopsis = 'Gets the current Invoke-Build version.'
	inputs = @()
	outputs = @{ type = 'System.Version' }
	examples = @{
		code = {assert ((Get-BuildVersion).Major -ge 2)}
		remarks = @'
This command works like `require version`. It can be used as the first command
in a build script in order to ensure that the script is being built by a proper
engine (version 2+).
'@
	}
}

### Invoke-BuildExec
@{
	command = 'Invoke-BuildExec'
	synopsis = 'Invokes the command and checks for the $LastExitCode.'
	description = @'
	Its recommended alias is 'exec'. It invokes the specified script block
	which is supposed to call an executable. Then the $LastExitCode is checked.
	By default if the code is not 0 then the function throws an error.

	It is common to call .NET tools, e.g. MSBuild. See Use-BuildAlias.
'@
	parameters = @{
		Command = @'
		A command that invokes an executable which exit code is checked. It is
		mandatory to invoke an external application, directly (.exe) or not
		(.cmd, .bat, etc.), otherwise $LastExitCode is not set or contains an
		exit code of another command.
'@
		ExitCode = @'
		Valid exit codes (e.g. 0..3 for robocopy). The default is 0.
'@
	}
	inputs = @()
	outputs = @(
		@{
			type = 'Objects'
			description = @'
		Outputs of the command and the tool that it invokes.
'@
		}
	)
	examples = @(
		@{
			code = {
	# Call robocopy (0..3 are valid exit codes):
	exec { robocopy Source Target /mir } (0..3)
			}
		}
	)
	links = @(
		@{ text = 'Use-BuildAlias' }
	)
}

### Use-BuildAlias
@{
	command = 'Use-BuildAlias'
	synopsis = '(use) Sets framework/directory tool aliases.'
	description = @'
	Its recommended alias is 'use'. Invoke-Build does not change the system
	path in order to make framework tools available by names. This is not
	suitable for using mixed framework tools (in different tasks, scripts,
	parallel builds). Instead, this function is used for setting tool aliases
	in the scope where it is called from.

	This function is often called from a build script and all tasks use script
	scope aliases. But it can be called from tasks in order to use more tools
	including other frameworks or tool directories.

	MSBuild is one of frequently used tools. Its samples:

		use Framework\v4.0.30319 MSBuild
		use Framework\v3.5 MSBuild
		use Framework\v2.0.50727 MSBuild
'@
	parameters = @{
		Path = @'
		The tool directory. If it is like Framework* then it is assumed to be
		relative to Microsoft.NET in the Windows directory. Otherwise it is a
		full or relative literal path of any directory, not necessarily .NET.

		Examples: Framework\v4.0.30319, Framework\v2.0.50727, .\Tools
'@
		Name = @'
		Tool names to set aliases for. These names also become aliases and they
		should be used later exactly as specified in here.
'@
	}
	inputs = @()
	outputs = @()
	examples = @(
		@{
			code = {
	# Use .NET 4.0 tools MSBuild, csc, ngen. Then call MSBuild.
	use Framework\v4.0.30319 MSBuild, csc, ngen
	exec { MSBuild Some.csproj /t:Build /p:Configuration=Release }
			}
		}
	)
	links = @(
		@{ text = 'Invoke-BuildExec' }
	)
}

### Write-Build
@{
	command = 'Write-Build'
	synopsis = 'Writes colored text (if this makes sense for the output).'
	description = @'
	This function is used in order to output colored text (e.g. to a console).
	Unlike Write-Host it is suitable for redirected output, e.g. to a file.
'@
	parameters = @{
		Color = @'
		[System.ConsoleColor] value or its string representation.
'@
		Text = @'
		Text to be printed using colors or just sent to the output.
'@
	}
	inputs = @()
	outputs = @(
		@{
			type = 'String'
		}
	)
}

### Get-BuildFile
@{
	command = 'Get-BuildFile'
	synopsis = @'
	Gets full path of the default build file in a directory.
'@
	description = @'
	This function is not designed for build scripts and tasks. It is used
	internally and exposed only for Get-BuildFileHook in wrapper scripts.
'@
	parameters = @{
		Path = @'
		A full directory path used to get the default build file. A file does
		not have to be located in this directory.
'@
	}
	inputs = @()
	outputs = @{ type = 'String' }
}

### Invoke-Builds.ps1
@{
	command = 'Invoke-Builds.ps1'
	synopsis = @'
	Invokes parallel builds by Invoke-Build.ps1
'@
	description = @'
	This script invokes build scripts simultaneously using Invoke-Build.ps1
	which has to be in the same directory. Number of simultaneous builds is
	limited by the number of processors by default.
'@
	parameters = @{
		Build = @'
		Build parameters defined as hashtables with these keys/data:
		* Task, File, Parameters - Invoke-Build.ps1 parameters
		* Log - Tells to write build output to the specified file

		Any number of builds is allowed, including 0 and 1. Maximum number of
		parallel builds is limited by number of processors by default. It can
		be changed by the parameter MaximumBuilds.

		If exactly a [hashtable[]] (not [object[]]) is passed in then after the
		call it contains modified copies of input hashtables used as parameters
		passed in Invoke-Build. Their Result.Value contain build result info.
'@
		Result = @'
		Tells to output build results using a variable. It is either a name of
		variable to be created for results or any object with the property
		Value to be assigned ([ref], [hashtable]).

		Result properties:
		* Tasks - tasks (see: help Invoke-Build -Parameter Result)
		* Errors - error messages
		* Warnings - warning messages
		* Started - start time
		* Elapsed - elapsed time span
'@
		Timeout = @'
		Maximum overall build time in milliseconds.
'@
		MaximumBuilds = @'
		Maximum number of builds invoked at the same time.
'@
	}
	inputs = @()
	outputs = @{
		type = 'text'
		description = 'Output of invoked builds and other log messages.'
	}
	examples = @(
		@{
			code = {
				Invoke-Builds @(
					@{File='Project1.build.ps1'}
					@{File='Project2.build.ps1'; Task='MakeHelp'}
					@{File='Project2.build.ps1'; Task='Build', 'Test'}
					@{File='Project3.build.ps1'; Log='C:\TEMP\Project3.log'}
					@{File='Project4.build.ps1'; Parameters=@{Configuration='Release'}}
				)
			}
			remarks = @'
	Five parallel builds are invoked with various combinations of parameters.
	Note that it is fine to invoke the same build script more than once if
	build flows specified by different tasks do not conflict.
'@
		}
	)
	links = @(
		@{ text = 'Invoke-Build' }
	)
}
