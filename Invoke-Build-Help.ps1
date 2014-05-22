
<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

### Invoke-Build.ps1
@{
	command = 'Invoke-Build.ps1'
	synopsis = 'Invoke-Build - Build Automation in PowerShell'

	description = @'
	Install: copy Invoke-Build.ps1 and Invoke-Build.ps1-Help.xml to the path.

	This script invokes specified tasks defined in a PowerShell script. This
	process is called build and its concepts are similar to psake and MSBuild.

	A build script defines parameters, variables, tasks, and events. Any code
	is invoked with the current location set to $BuildRoot, the build script
	directory. $ErrorActionPreference is set to 'Stop'.

	In order to get help for special functions dot-source
	Invoke-Build.ps1 by the operator . and then use Get-Help:

		PS> . Invoke-Build.ps1  # shows special function names
		PS> Get-Help <function> # get help for a function

	RESERVED FUNCTION AND VARIABLE NAMES

	Function and variable names starting with "*" are reserved for the engine.
	For technical reasons they cannot be completely hidden from scripts.
	Scripts should not use functions and variables with such names.

	EXPOSED FUNCTIONS AND ALIASES

	Scripts should use available aliases instead of function names.

		Add-BuildTask (task)
		Assert-Build (assert)
		Get-BuildError (error)
		Get-BuildProperty (property)
		Get-BuildVersion
		Invoke-BuildExec (exec)
		New-BuildJob (job)
		Use-BuildAlias (use)
		Write-Build
		Write-Warning [1]
		Get-BuildFile [2]

	[1] Write-Warning is redefined internally in order to count warnings in
	tasks, build, and other scripts. But warnings in modules are not counted.

	[2] Exists only as a pattern for wrappers.

	SPECIAL ALIASES

		Invoke-Build
		Invoke-Builds

	These aliases are for the scripts Invoke-Build.ps1 and Invoke-Builds.ps1.
	Use them for calling nested builds, i.e. omit script extensions and paths.
	With this rule Invoke-Build tools can be kept together with build scripts.

	EXPOSED VARIABLES

	Exposed variables designed for build scripts and tasks:

		$WhatIf    - WhatIf mode, Invoke-Build parameter
		$BuildRoot - build script location
		$BuildFile - build script path
		$BuildTask - initial tasks
		$Task      - current task

	$Task is available for the task script blocks defined by parameters If,
	Inputs, Outputs, Jobs and the event functions Enter|Exit-BuildTask and
	Enter|Exit-BuildJob.

		$Task properties available for reading:

		- Name - [string], task name
		- Jobs - [object[]], names and script blocks
		- Started - [DateTime], start time
		- In Exit-BuildTask:
		    - Error - an error stopped the task
		    - Elapsed - [TimeSpan], task duration

	NOTE: The special variable $_ may be defined and visible. Scripts and tasks
	can use it as their own, that is assign at first. Only in special cases it
	is used as an input.

	EVENT FUNCTIONS

	The build engine defines and calls the following empty functions:

		Enter-Build     - before all tasks
		Enter-BuildTask - before each task
		Enter-BuildJob  - before each job
		Exit-Build      - after all tasks
		Exit-BuildTask  - after each task
		Exit-BuildJob   - after each job
		Export-Build    - after each task of a persistent build
		Import-Build    - once on resuming of a persistent build

	A script can redefine them. Note that nested builds do not inherit events,
	the engine always defines new empty functions before invoking a new script.

	Events are not called on WhatIf. If Enter-* is called then its pair Exit-*
	is called, too. Events are suitable for initializing and cleaning things.

	Enter-Build and Exit-Build are invoked in the script scope. Enter-Build is
	a good place for heavy initialization, it does not have to care of WhatIf.

	Enter-BuildTask and Exit-BuildTask are invoked in the same scope which is
	the parent for a task invoked between them.

	Enter-BuildJob and Exit-BuildJob are invoked in the same scope as
	*-BuildTask and take one argument, the job number.

	Export-Build and Import-Build are used with persistent builds. Export-Build
	outputs data to be exported to clixml. Import-Build is called with a single
	argument containing the original data imported from clixml. It is called in
	the script scope and normally restores script scope variables. Note that
	this is not needed for script parameters, the engine takes care of them.
	Variables may be declared as parameters just in order to be persistent.
'@

	parameters = @{
		Task = @'
		One or more tasks to be invoked. If it is not specified, null, empty,
		or equal to '.' then the task '.' is invoked if it exists, otherwise
		the first added task is invoked.

		Names with wildcard characters are reserved for special tasks.

		SPECIAL TASKS

		? - Tells to list the tasks with brief information without invoking. It
		also checks tasks and throws errors on missing or cyclic references.
		Task synopsis is defined in preceding comments as # Synopsis: ...

		?? - Tells to collect and get all tasks as a ordered dictionary. It can
		be used by external tools for task analysis, TabExpansion, and etc.

		Tasks ? and ?? sets $WhatIf to true. Properly designed build scripts
		should not perform anything significant if $WhatIf is set to true.

		* - Tells to invoke all tasks. This is useful when all tasks are tests
		or steps in a sequence that can be stopped and resumed, see Checkpoint.

		** - Invokes * for all files *.test.ps1 found recursively in the
		current directory or a directory specified by the parameter File.
		Other parameters except Result are not used.

		Tasks ? and ?? can be combined with **
		?, ** - Tells to show all test tasks without invoking.
		??, ** - Tells to get task dictionaries for all test files.
'@
		File = @'
		A build script which defines tasks by the alias "task" (Add-BuildTask).

		If it is not specified then Invoke-Build looks for "*.build.ps1" files
		in the current location. A single file is used as the script. If there
		are more files then ".build.ps1" is used.

		If the build file is not found then a script defined by the environment
		variable InvokeBuildGetFile is called with the path as an argument. It
		may get a non standard build file. The full path is required.

		If the file is still not defined then parent directories are searched.
'@
		Parameters = @'
		A hashtable of parameters passed in the build script. It is needed only
		in special cases. Normally build script parameters may be specified for
		Invoke-Build itself, thanks to PowerShell dynamic parameters.

		Dynamic parameters and the table Parameters are not used together. If
		build script parameters conflict with Invoke-Build parameters then the
		table Parameters is the only way to pass them in the script.

		Build scripts define parameters using standard syntax. Parameters are
		shared between tasks: for reading as $ParameterName, for writing as
		$script:ParameterName.

		Build script parameters are automatically exported and imported by the
		engine on persistent builds, see Checkpoint.
'@
		Checkpoint = @'
		Specifies the checkpoint file and makes the build persistent. It is
		possible to resume an interrupted build starting at an interrupted
		task. The checkpoint file is written after each completed task and
		deleted when the build completes.

		In order to resume an interrupted persistent build specify the same
		checkpoint file and the switch Resume. The tasks, build file and
		parameters are ignored on resuming, their values are restored.

		Persistent builds must be designed properly. Data shared by tasks are
		exported and imported by the functions Export-Build and Import-Build.

		Note that this is not needed for script parameters, the engine takes
		care of them. Some variables may be declared as parameters simply in
		order to be persistent and custom export and import may be avoided.

		Notes
		- Think carefully of what the persistent build state is.
		- Some data are not suitable for persistence in clixml files.
		- Changes in stopped build scripts may cause incorrect resuming.
		- Checkpoint files must not be used with different engine versions.
'@
		Resume = @'
		Tells to resume an interrupted persistent build from a checkpoint file
		specified by Checkpoint. Initial tasks, build files and parameters are
		ignored on resuming, values are restored from the file.
'@
		Result = @'
		Tells to output build information using a variable. It is either a name
		of variable to be created or any object with the property Value to be
		assigned (e.g. a [ref] or [hashtable]).

		Result object properties:

			All - all defined tasks
			Error - a terminating build error
			Tasks - invoked tasks including nested
			Errors - error records including nested (*)
			Warnings - warning messages including nested

		(*) This list will continue to exist but objects may change in the
		future. For better analysis iterate through Tasks and check their
		Error.

		Task object properties:

			Name - task name
			Jobs - task jobs
			Error - task error
			Started - start time
			Elapsed - task duration
			InvocationInfo{.ScriptName|.ScriptLineNumber} - task location.

		Other result and task data should not be used. These data should not be
		changed, especially if they are requested for a nested build, parent
		builds use these data.
'@
		Safe = @'
		Tells to catch a build failure, store an error as the property Error of
		Result and return quietly. A caller should use Result and check its
		Error in order to analyse build failures.

		Some exceptions are possible even in safe mode. They show serious
		errors, not build failures. For example, a build script is missing.
'@
		Summary = @'
		Tells to show summary information after the build. It includes task
		durations, names, locations, and error messages.
'@
		WhatIf = @'
		Tells to show preprocessed tasks and their scripts instead of invoking
		them. If a script does anything but adding and configuring tasks then
		it should check for $WhatIf and skip some significant actions.
'@
	}

	outputs = @(
		@{
			type = 'Text'
			description = @'
		Build process log which includes task starts, ends with durations,
		warnings, errors, and output of tasks and commands that they invoke.

		Build scripts should not output anything. Unexpected output is shown as
		a warning. Output is expected from tasks and special event functions.
'@
		}
	)

	examples = @(
		@{code={
	# Invoke the default task ("." or the first added) in the default script
	# (a single file like *.build.ps1 or .build.ps1 if there are two or more)

	Invoke-Build
		}}

		@{code={
	# Invoke tasks Build and Test from the default script with parameters.
	# The script defines parameters Log and WarningLevel by 'param' as usual.

	Invoke-Build Build, Test -Log log.txt -WarningLevel 4
		}}

		@{code={
	# Show tasks in the default script and the specified script

	Invoke-Build ?
	Invoke-Build ? Project.build.ps1

	# Custom formatting is possible, too

	Invoke-Build ? | Format-Table -AutoSize
	Invoke-Build ? | Format-List Name, Synopsis
		}}

		@{code={
	# Get task names without invoking for listing, TabExpansion, etc.

	$all = Invoke-Build ??
	$all.Keys
		}}

		@{code={
	# Invoke all in Test1.test.ps1 and all in Tests\...\*.test.ps1

	Invoke-Build * Test1.test.ps1
	Invoke-Build ** Tests
		}}

		@{code={
	# Invoke a persistent sequence of steps defined as tasks
	Invoke-Build * Steps.build.ps1 -Checkpoint temp.clixml

	# Resume the above steps at the stopped one
	Invoke-Build -Checkpoint temp.clixml -Resume
		}}

		@{code={
	# Using the build results, e.g. for performance analysis

	# Invoke the build and keep results in the variable Result
	Invoke-Build -Result Result

	# Show invoked tasks ordered by Elapsed with ScriptName included
	$Result.Tasks |
	Sort-Object Elapsed |
	Format-Table -AutoSize Elapsed, @{
		Name = 'Task'
		Expression = {$_.Name + ' @ ' + $_.InvocationInfo.ScriptName}
	}
		}}

		@{code={
	# Using the build results, e.g. for tasks summary

	try {
		# Invoke the build and keep results in the variable Result
		Invoke-Build -Result Result
	}
	finally {
		# Show task summary information after the build
		$Result.Tasks | Format-Table Elapsed, Name, Error -AutoSize
	}
		}}
	)

	links = @(
		@{ text = 'Wiki'; URI = 'https://github.com/nightroman/Invoke-Build/wiki' }
		@{ text = 'Project'; URI = 'https://github.com/nightroman/Invoke-Build' }
		@{ text = 'Add-BuildTask' }
		@{ text = 'Assert-Build' }
		@{ text = 'Get-BuildError' }
		@{ text = 'Get-BuildProperty' }
		@{ text = 'Invoke-BuildExec' }
		@{ text = 'New-BuildJob' }
		@{ text = 'Use-BuildAlias' }
		@{ text = 'Write-Build' }
	)
}

### Add-BuildTask
@{
	command = 'Add-BuildTask'
	synopsis = 'Defines a build task and adds it to the internal task list.'

	description = @'
	Scripts use its alias 'task'. This is the main feature of build scripts.
	At least one task must be added. It is used in the build script scope only.

	In fact, this feature is literally all that build scripts really need.
	Other functions are mostly helpers, scripts do not have to use them.

	Task synopsis is defined in preceding comments as # Synopsis: ...
	It is used in task information returned by Invoke-Build ?
'@

	parameters = @{
		Name = @'
		The task name. Wildcard characters are deprecated. Duplicated names are
		allowed, each added task overrides previously added with the same name.
'@
		Jobs = @'
		Specifies the task jobs. Jobs are other task references and own
		actions. Any number of jobs is allowed. Jobs are invoked in the
		specified order.

		Valid job types are:

			[string] - simple reference, name of an existing task;
			[object] - advanced reference created by 'job' (New-BuildJob);
			[scriptblock] - action, a script block invoked for this task.
'@
		After = @'
		Tells to add this task to the end of the specified task job lists.

		Altered tasks are defined as by their names or by the command 'job'.
		In the latter case options are applied to the added task reference.

		Parameters After and Before are used in order to alter build task jobs
		in special cases when direct changes in task jobs are not suitable.
'@
		Before = @'
		Tells to add this task to job lists of the specified tasks. It is
		inserted before the first script job, if any, or added to the end.

		See the parameter After for details.
'@
		If = @'
		Tells whether to invoke the task or skip it. The default is $true. The
		value is a script block evaluated on task invocation or any other that
		is treated as Boolean on definition. In WhatIf mode a scriptblock is
		treated as $true without invocation.

		If it is a script block and the task is called several times then it is
		possible that the task is skipped at first but invoked later when this
		block gets true.
'@
		Inputs = @'
		Tells to process the task as incremental and requires the parameter
		Outputs with the optional switch Partial.

		Inputs are file items or paths or a script block which gets them.
		Outputs are file paths or a script block which gets them.

		Automatic variables for task script jobs:

			$Inputs - full input paths, array of strings
			$Outputs - result of the evaluated parameter Outputs

		With the switch Partial the task is processed as partial incremental.
		There must be one-to-one correspondence between Inputs and Outputs.

		Partial Outputs are file paths or a script block which is invoked with
		input paths piped to it in order to transform them into output paths.

		In addition to automatic variables $Inputs and $Outputs, inside
		process{} blocks of a partial task two more variables are defined:

			$_ - current full input path
			$2 - current output path

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
		Done = @'
		Specifies the command or a script block invoked when the task is done.
'@
		Data = @'
		Any data attached to the task. These data are not used by the engine.
		When the task is invoked the data are available as $Task.Data.
'@
		Source = @'
		Specifies the task source. It is used by task wrappers in order to
		provide actual source needed for location messages and help synopsis.
'@
	}

	links = @(
		@{ text = 'New-BuildJob' }
		@{ text = 'Get-BuildError' }
		@{ URI = 'https://github.com/nightroman/Invoke-Build/wiki/Script-Tutorial' }
		@{ URI = 'https://github.com/nightroman/Invoke-Build/wiki/Incremental-Tasks' }
		@{ URI = 'https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks' }
	)
}

### New-BuildJob
@{
	command = 'New-BuildJob'
	synopsis = 'Creates a new task reference with options.'

	description = @'
	Scripts use its alias 'job'. It is called on job list creation for a task.
	It creates a reference to another task with options. The only used option
	is the switch Safe.
'@

	parameters = @{
		Name = @'
		The referenced task name.
'@
		Safe = @'
		Tells to create a safe task job. If the referenced task fails the build
		continues if this task is safe everywhere in the current build. Other
		tasks use 'error' (Get-BuildError) in order to check for errors.
'@
	}

	outputs = @{
		type = 'Object'
		description = 'A new job used as an argument on task creation.'
	}

	links = @(
		@{ text = 'Get-BuildError' }
	)
}

### Get-BuildError
@{
	command = 'Get-BuildError'
	synopsis = 'Gets an error of the specified task if the task has failed.'

	description = @'
	Scripts use its alias 'error'. It is used when some tasks are referenced
	safe as (job Task -Safe) in order to analyse their potential errors.
'@

	parameters = @{
		Task = @'
		Name of the task which error is requested.
'@
	}

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
		@{ text = 'New-BuildJob' }
	)
}

### Assert-Build
@{
	command = 'Assert-Build'
	synopsis = 'Checks for a condition.'

	description = @'
	Scripts use its alias 'assert'. It checks for a condition and if it is not
	true throws an error with an optional message text.
'@

	parameters = @{
		Condition = @'
		The condition.
'@
		Message = @'
		A user friendly message describing the assertion condition.
'@
	}
}

### Get-BuildProperty
@{
	command = 'Get-BuildProperty'
	synopsis = 'Gets PowerShell or environment variable or the default.'

	description = @'
	Scripts use its alias 'property'. It gets the first not null value of these
	three: PowerShell variable, environment variable, specified default value.
	Otherwise an error is thrown.

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

	outputs = @(
		@{
			type = 'Object'
			description = @'
		Requested property value.
'@
		}
	)

	examples = @(
		@{code={
	# Inherit the existing value or throw an error

	$OutputPath = property OutputPath
		}}

		@{code={
	# Get an existing value or use the default

	$WarningLevel = property WarningLevel 4
		}}
	)
}

### Get-BuildVersion
@{
	command = 'Get-BuildVersion'
	synopsis = 'Gets the current Invoke-Build version.'

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
	Scripts use its alias 'exec'. It invokes the specified script block which
	is supposed to call an executable. Then the $LastExitCode is checked. By
	default if the code is not 0 then the function throws an error.

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

	outputs = @(
		@{
			type = 'Objects'
			description = @'
		Outputs of the command and the tool that it invokes.
'@
		}
	)

	examples = @(
		@{code={
	# Call robocopy (0..3 are valid exit codes)

	exec { robocopy Source Target /mir } (0..3)
		}}
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
	Scripts use its alias 'use'. Invoke-Build does not change the system path
	in order to make framework tools available by names. This is not suitable
	for using mixed framework tools (in different tasks, scripts, parallel
	builds). Instead, this function is used for setting tool aliases in the
	scope where it is called from.

	This function is often called from a build script and all tasks use script
	scope aliases. But it can be called from tasks in order to use more tools
	including other frameworks or tool directories.

	MSBuild is one of frequently used tools. Examples:

		use 4.0 MSBuild
		use Framework\v2.0.50727 MSBuild
'@

	parameters = @{
		Path = @'
		Specifies the tools directory.

		If it starts with digits followed by a dot then it is assumed to be a
		MSBuild version and the path is taken from the registry.

		If it is like Framework* then it is assumed to be a path relative to
		Microsoft.NET in the Windows directory.

		Otherwise it is a full or relative literal path of any directory.

		Examples: 4.0, Framework\v4.0.30319, Framework\v2.0.50727, .\Tools
'@
		Name = @'
		Tool names to set aliases for. These names also become aliases and they
		should be used later exactly as specified in here.
'@
	}

	examples = @(
		@{code={
	# Use .NET 4.0 tools MSBuild, csc, ngen. Then call MSBuild.

	use 4.0 MSBuild, csc, ngen
	exec { MSBuild Some.csproj /t:Build /p:Configuration=Release }
		}}
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

	outputs = @(
		@{
			type = 'String'
		}
	)
}

### Get-BuildFile
@{
	command = 'Get-BuildFile'
	synopsis = 'Gets full path of the default build file in a directory.'

	description = @'
	This function is not designed for build scripts and tasks. It is used
	internally and exists only as a pattern to follow for wrapper scripts.
'@

	parameters = @{
		Path = @'
		A full directory path used to get the default build file. A file does
		not have to be located in this directory.
'@
	}

	outputs = @{ type = 'String' }
}

### Invoke-Builds.ps1
@{
	command = 'Invoke-Builds.ps1'
	synopsis = 'Invokes parallel builds by Invoke-Build.ps1'

	description = @'
	This script invokes build scripts simultaneously using Invoke-Build.ps1
	which has to be in the same directory. Number of simultaneous builds is
	limited by the number of processors by default.
'@

	parameters = @{
		Build = @'
		Build parameters defined as hashtables with these keys/data:

			Task, File, Parameters - Invoke-Build.ps1 parameters
			Log - Tells to write build output to the specified file

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

			Tasks - tasks (see: help Invoke-Build -Parameter Result)
			Errors - error records (*)
			Warnings - warning messages
			Started - start time
			Elapsed - build duration

		(*) This list will continue to exist but objects may change in the
		future. For better analysis iterate through Tasks and check their
		Error.
'@
		Timeout = @'
		Maximum overall build time in milliseconds.
'@
		MaximumBuilds = @'
		Maximum number of builds invoked at the same time.
'@
	}

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
