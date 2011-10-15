
<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

### Invoke-Build.ps1 command help
@{
	command = 'Invoke-Build.ps1'
	synopsis = 'Invoke-Build.ps1 - Build Automation in PowerShell'
	description = @'
	Install: copy Invoke-Build.ps1 and Invoke-Build.ps1-Help.xml to the path.

	This script is a simple and yet robust build automation tool with build
	scripts written in PowerShell and concepts similar to MSBuild and psake.

	Build scripts define parameters, variables, and tasks. Scripts and tasks
	are invoked with the current location set to the build script directory,
	$BuildRoot. Default $ErrorActionPreference is set to 'Stop'.

	Dot-source Invoke-Build only in order to get help for its functions.

	EXPOSED FUNCTIONS AND ALIASES

		* Add-BuildTask (task)
		* Assert-BuildTrue (assert)
		* Get-BuildError (error)
		* Get-BuildProperty (property)
		* Get-BuildVersion
		* Invoke-BuildExec (exec)
		* Use-BuildAlias (use)
		* Write-BuildText
		* Write-Warning [1]

	[1] Write-Warning is redefined internally in order to count warnings in
	tasks, build and other scripts. But warnings in modules are not counted.

	EXPOSED VARIABLES

	Only documented variables should be visible for build scripts and tasks.

	Exposed variables designed for build scripts and tasks:

		* WhatIf    - WhatIf mode, Invoke-Build parameter
		* BuildRoot - build script directory (by default)
		* BuildFile - build script file path
		* BuildTask - invoked task names

	Variables for internal use by the engine:

		* BuildInfo, BuildList
'@
	parameters = @{
		Task = @'
		One or more tasks to be invoked. If it is not specified, null, empty,
		or equal to '.' then the task '.' is invoked if it exists, otherwise
		the first added task, including imported, is invoked.

		Names starting with '?' are reserved for special engine commands:
		? - tells to list the tasks without invoking.
'@
		File = @'
		The build script which defines build tasks by Add-BuildTask (task).

		If it is not specified then Invoke-Build looks for "*.build.ps1" files
		in the current location. A single file is used as the script. If there
		are more files then ".build.ps1" is used as the default.
'@
		Parameters = @'
		A hashtable of parameters passed in the build script. Scripts define
		parameters as usual using standard PowerShell syntax. Parameters are
		available for all tasks: for reading simply as $ParameterName, for
		writing as $script:ParameterName. This is true as well for other
		variables defined in the script scope.
'@
		Result = @'
		Specifies the variable name for the task collection or build results.

		If the Task is '?' then the build script is invoked with WhatIf set,
		tasks are collected in the result variable and build is not invoked.

		Otherwise tasks are invoked and the variable contains the results.

		Result object properties:
		* Tasks, AllTasks - own invoked tasks and with nested
		* Messages, AllMessages - own build messages and with nested
		* ErrorCount, AllErrorCount - own error count and with nested
		* WarningCount, AllWarningCount - own warning count and with nested

		Task objects contain various runtime information. These documented
		properties are valid for analysis:
		* Name - task name
		* Error - task error
		* Started - start time
		* Elapsed - task duration
		* Info - System.Management.Automation.InvocationInfo:
		- Info.ScriptName, Info.ScriptLineNumber - where the task is defined.

		Other result and task data should not be used. Also, these data should
		not be changed, especially if they are requested for a nested build,
		parent builds are still using these data.
'@
		WhatIf = @'
		Tells to show preprocessed tasks and their scripts instead of invoking
		them. If a script does anything but adding and configuring tasks then
		it may check for $WhatIf and skip some actions if it is true.
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
	$Result.AllTasks |
	Sort-Object Elapsed |
	Format-Table -AutoSize Elapsed, @{
		Name = 'Task'
		Expression = {$_.Name + ' @ ' + $_.Info.ScriptName}
	} |
	Out-String
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
		$result.AllTasks |
		Format-Table Elapsed, Name, Error -AutoSize |
		Out-String
	}
			}
		}
	)
	links = @(
		@{ text = 'Wiki'; URI = 'https://github.com/nightroman/Invoke-Build/wiki' }
		@{ text = 'Project'; URI = 'https://github.com/nightroman/Invoke-Build' }
		@{ text = 'Add-BuildTask' }
		@{ text = 'Assert-BuildTrue' }
		@{ text = 'Get-BuildError' }
		@{ text = 'Get-BuildProperty' }
		@{ text = 'Invoke-BuildExec' }
		@{ text = 'Use-BuildAlias' }
		@{ text = 'Write-BuildText' }
	)
}

### Add-BuildTask command help
@{
	command = 'Add-BuildTask'
	synopsis = '(task) Defines a build task and adds it to the internal task list.'
	description = @'
	This is the key function of build scripts. It creates build tasks, defines
	dependencies and invocation order, and adds the tasks to the internal list.
	It is called from build scripts, not from their tasks.

	In fact, this function is literally all that build scripts really need.
	Other build functions are just helpers, scripts do not have to use them.
'@
	parameters = @{
		Name = @'
		The task name. Names starting with '?' are reserved for the engine.

		Consider to use simple names without punctuation. Task names are used
		in the protected call notation @{TaskName = 1}. If a name is simple
		then it is easy to use there. Compare:
		@{TaskName = 1}    # name is used as it is
		@{'Task-Name' = 1} # name has to be used with ' or "
'@
		Jobs = @'
		The task jobs. The following types are supported:
		* [string] - task jobs, existing task names;
		* [hashtable] - task jobs with options, @{TaskName = Option};
		* [scriptblock] - script jobs, script blocks invoked for this task.

		Notation @{TaskName = Option} references the task TaskName and assigns
		the Option to it. The only supported now option value is 1: protected
		task call. It tells to ignore task errors if other active tasks also
		call TaskName as protected.
'@
		After = @'
		Tells to add this task to job lists of the specified tasks. It is added
		after the last script job, if any, otherwise to the end.

		Altered tasks are defined as names or constructs @{Task = 1}. In the
		latter case this extra task is called protected (see the parameter
		Jobs details).

		Parameters After and Before are used in order to alter build task jobs
		in special cases when direct changes in task jobs are not suitable.
'@
		Before = @'
		Tells to add this task to job lists of the specified tasks. It is added
		before the first script job, if any, otherwise to the end (yes, to the
		end, so that the original dependent tasks are invoked first).

		See the parameter After for details.
'@
		If = @'
		Tells whether to invoke the task ($true) or skip it ($false). The
		default is $true. The value is either a script block evaluated on
		task invocation or any value treated as Boolean.

		If it is a script block and the task is called several times then it is
		possible that the task is at first skipped but still invoked later when
		this block finally gets true.
'@
		Incremental = @'
		Tells to process the task as incremental. It is a hashtable with a
		single entry where the key is inputs and the value is outputs.

		Inputs and outputs are file system items or literal paths or a script
		block which gets them.

		Automatic variables for task script jobs:
		- $Inputs - full input paths, ArrayList with strings
		- $Outputs - outputs, [string] or [string[]]

		See more about incremental tasks:
		https://github.com/nightroman/Invoke-Build/wiki/Incremental-Tasks
'@
		Partial = @'
		Tells to process the task as partial incremental. It is a hashtable
		with a single entry where the key is inputs and the value is outputs.
		There must be one-to-one correspondence between input and output items.

		Inputs and outputs are file system items or literal paths or a script
		block which gets them.

		If the outputs value is defined as a script block then it is invoked
		with input items piped to it.

		Automatic variables for script jobs:
		- $Inputs - full input paths, ArrayList with strings
		- $Outputs - outputs (transformed inputs), ArrayList

		In addition, inside process{} blocks:
		- $_ - the current full input path
		- $$ - the current output path

		See more about partial incremental tasks:
		https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks
'@
	}
	inputs = @()
	outputs = @()
	links = @(
		@{ text = 'Get-BuildError' }
	)
}

### Get-BuildError command help
@{
	command = 'Get-BuildError'
	synopsis = '(error) Gets an error of the specified task if the task has failed.'
	description = @'
	This method is used when some dependent tasks are referenced as @{Task=1}
	(protected) and the current task script is about to analyse their errors.
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

### Assert-BuildTrue command help
@{
	command = 'Assert-BuildTrue'
	synopsis = '(assert) Checks for a condition.'
	description = @'
	It checks for a condition and if it is not true throws a message.
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

### Get-BuildProperty command help
@{
	command = 'Get-BuildProperty'
	synopsis = @'
	(property) Gets PowerShell or environment variable or the default.
'@
	description = @'
	It gets the first found not null value of these three: PowerShell variable,
	environment variable, specified default value. If nothing is defined and
	not null then an error is thrown.

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

### Get-BuildVersion command help
@{
	command = 'Get-BuildVersion'
	synopsis = 'Gets Invoke-Build version.'
	inputs = @()
	outputs = @{ type = 'System.Version' }
}

### Invoke-BuildExec command help
@{
	command = 'Invoke-BuildExec'
	synopsis = '(exec) Invokes the command and checks for the $LastExitCode.'
	description = @'
	The passed in command is supposed to call an executable tool. This function
	invokes the command and checks for the $LastExitCode. By default if the
	code is not zero then the function throws a terminating error.

	It is common to call .NET framework tools. See Use-BuildAlias.
'@
	parameters = @{
		Command = @'
		The command that invokes an executable which exit code is checked.
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

### Use-BuildAlias command help
@{
	command = 'Use-BuildAlias'
	synopsis = '(use) Sets framework/directory tool aliases.'
	description = @'
	Invoke-Build does not change the system path in order to make framework
	tools available by names. This approach would be not suitable for using
	mixed framework tools simultaneously. Instead, this function is used in
	order to set framework aliases in the scope where it is called from.

	This function is often called from a build script and all tasks use script
	scope aliases. But it can be called from tasks in order to use more tools
	including other frameworks or tool directories.
'@
	parameters = @{
		Path = @'
		The tool directory. Null or empty assumes the current .NET runtime
		directory. If it starts with 'Framework' then it is assumed to be
		relative to Microsoft.NET in the Windows directory. Otherwise it is
		used literally, it can be any directory with any tools.

		Examples: Framework\v4.0.30319, Framework\v2.0.50727, C:\Scripts, etc.
'@
		Name = @'
		The tool names to set aliases for. These names also become alias names
		and they should be used exactly as specified.
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

### Write-BuildText command help
@{
	command = 'Write-BuildText'
	synopsis = 'Writes text using colors (if this makes sense for the output target).'
	description = @'
	Unlike Write-Host this function is suitable for output sent to a file.
'@
	parameters = @{
		Color = @'
		The [System.ConsoleColor] value or its string representation.
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
