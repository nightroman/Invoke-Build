<#
.Synopsis
	Help script (https://github.com/nightroman/Helps)
#>

### Invoke-Build.ps1
@{
	command = 'Invoke-Build.ps1'
	synopsis = 'Invoke-Build - Build Automation in PowerShell'

	description = @'
	The command invokes so called tasks defined in a PowerShell script.
	Let's call this process build and a script with tasks build script.

	A build script defines parameters, variables, and one or more tasks.
	Any code is invoked with the current location set to $BuildRoot,
	the script directory. $ErrorActionPreference is set to 'Stop'.

	SCRIPT PARAMETERS

	Build scripts define parameters as usual using the param() block.
	On calling, specify them for Invoke-Build as if they are its own.

	Known issue #4. Specify script switches after Task and File.

	These parameters are reserved for Invoke-Build:
	Task, File, Result, Safe, Summary, WhatIf

	COMMANDS AND HELP

	Commands available for build scripts:

		task      (Add-BuildTask)
		exec      (Invoke-BuildExec)
		assert    (Assert-Build)
		equals    (Assert-BuildEquals)
		remove    (Remove-BuildItem)
		property  (Get-BuildProperty)
		requires  (Test-BuildAsset)
		use       (Use-BuildAlias)

		Confirm-Build
		Get-BuildError
		Get-BuildSynopsis
		Get-BuildVersion
		Resolve-MSBuild
		Set-BuildFooter
		Set-BuildHeader
		Use-BuildEnv
		Write-Build
		Write-Warning [1]

	[1] Write-Warning is redefined internally in order to count warnings in
	a build script and others called. Warnings in modules are not counted.

	To get commands help, dot-source Invoke-Build and then call help:

		PS> . Invoke-Build
		PS> help task -full

	SPECIAL ALIASES

		Invoke-Build
		Build-Parallel
		Build-Checkpoint

	Aliases are for scripts from the package. Use aliases for calling nested
	builds, i.e. omit ".ps1" extensions, to avoid accidentally calling other
	scripts with same names in the path.

	PUBLIC VARIABLES

		$OriginalLocation - where the build is invoked
		$WhatIf - WhatIf mode, Invoke-Build parameter
		$BuildRoot - build script location, by default
		$BuildFile - build script path
		$BuildTask - initial tasks
		$Task - current task
		$Job - current job

	All variables except $BuildRoot are for reading and should not be changed.
	$BuildRoot may be changed on loading by top level script code, in order to
	alter the default build directory, and should not be changed after loading.

	$Task is available for script blocks defined by task parameters If, Inputs,
	Outputs, and Jobs and by blocks Enter|Exit-BuildTask, Enter|Exit-BuildJob,
	Set-BuildHeader, Set-BuildFooter.

		$Task properties for reading:

		- Name - [string], task name
		- Jobs - [object[]], task jobs
		- Started - [DateTime], task start time

		And in Exit-BuildTask:

		- Error - task error or null
		- Elapsed - [TimeSpan], task duration

		Other properties should not be used by scripts.

	$Task also exists in the script scope with the only property Name getting
	$BuildFile, the build script path.

	BUILD BLOCKS

	Scripts may define special build blocks invoked as:

		Enter-Build {} - before the first task
		Exit-Build {} - after the last task

		Enter-BuildTask {} - before each task
		Exit-BuildTask {} - after each task

		Enter-BuildJob {} - before each task script job
		Exit-BuildJob {} - after each task script job

		Set-BuildHeader {param($Path)} - to write task headers
		Set-BuildFooter {param($Path)} - to write task footers

	Blocks are not called on WhatIf.
	Nested builds do not inherit Enter/Exit blocks.
	Nested builds inherit Set-BuildHeader and Set-BuildFooter.
	If Enter-X is called then Exit-X is also called, even on failures.

	Enter-Build and Exit-Build are invoked in the script scope. Enter-Build is
	suitable for initialization and it may output text unlike top level code.

	Enter-BuildTask, Exit-BuildTask, Enter-BuildJob, and Exit-BuildJob are
	invoked in the same scope, the parent of task script blocks.

	PRIVATE STUFF

	Function and variable names starting with '*' are reserved for the engine.
'@

	parameters = @{
		Task = @'
		One or more tasks to invoke. If it is omitted, empty, or equal to '.'
		then the task '.' is invoked if it exists, otherwise the first added
		task is invoked.

		Names with wildcard characters are reserved for special cases.

		SAFE REFERENCES

		If a task 'X' is referenced as '?X' then it is allowed to fail without
		breaking the build, i.e. other tasks specified after X will be invoked.

		SPECIAL TASKS

		? - Tells to show tasks synopses, jobs, and check for issues.
		Task synopses are defined in preceding comments as

			# Synopsis: ...

		or

			<#
			.Synopsis
			...
			#>

		?? - Tells to collect and get all tasks as an ordered dictionary.
		It can be used by external tools for analysis, completion, etc.

		Tasks ? and ?? set $WhatIf to true. Properly designed build scripts
		should not perform anything significant if $WhatIf is set to true.

		* - Tells to invoke all tasks, e.g. tests, step sequences, etc.
		The dot-task and tasks added by other scripts are not included.

		** - Invokes * for all files *.test.ps1 found recursively in the
		current directory or a directory specified by the parameter File.
'@
		File = @'
		The build script adding tasks by 'task' (Add-BuildTask).

		If File is omitted then Invoke-Build looks for *.build.ps1 files in the
		current location and takes the first in Sort-Object order.

		If the file is not found then a command set by the environment variable
		InvokeBuildGetFile is invoked with the directory path as an argument.
		This command may return the full path of a special build script.

		If the file is still not found then parent directories are searched.

		DIRECTORY PATH

		File accepts directory paths as well. The build script is resolved as
		described above for the specified directory without searching parents.

		INLINE SCRIPT

		File also accepts a script block composed as build script. In this
		case $BuildFile is a file defining the script block. $BuildRoot is
		its directory or $OriginalLocation when $BuildFile is null on
		[scriptblock]::Create() used instead of usual {...}.

		Script parameters, parallel, and persistent builds are not supported.
'@
		Result = @'
		Tells to make the build result. Normally it is the name of a variable
		created in the calling scope. Or it is a hashtable which entry Value
		contains the result.

		Result properties:

			All - all available tasks
			Error - a terminating build error
			Tasks - invoked tasks including nested
			Errors - error objects including nested
			Warnings - warning objects including nested
			Redefined - list of original redefined tasks

		Tasks is a list of objects:

			Name - task name
			Jobs - task jobs
			Error - task error
			Started - start time
			Elapsed - task duration
			InvocationInfo - task location (.ScriptName, .ScriptLineNumber)

		Errors is a list of objects:

			Error - original error
			File - current $BuildFile
			Task - current $Task or null for other errors

		Warnings is a list of objects:

			Message - warning message
			File - script emitting the warning
			Task - current $Task or null for other warnings

		Do not change these data and do not use not documented members.
'@
		Safe = @'
		Tells to catch a build failure, store an error as the property Error of
		Result and return quietly. A caller should use Result and check Error.

		Exceptions are still thrown if the build cannot start, for example:
		build script is missing, invalid, has no tasks.

		When Safe is used together with the special task ** (invoke *.test.ps1)
		then task failures stop current test scripts, not the whole testing.
'@
		Summary = @'
		Tells to show summary information after the build. It includes task
		durations, names, locations, and error messages.
'@
		WhatIf = @'
		Tells to show tasks and jobs to be invoked and some analysis of used
		parameters and environment variables. See Show-TaskHelp for details.

		If a script does anything but adding tasks then it should check for
		$WhatIf and skip actions on true. Consider using Enter-Build instead.
'@
	}

	outputs = @(
		@{
			type = 'Text'
			description = @'
		Build log which includes task records and engine messages, warnings,
		errors, and output from build script tasks and special blocks.

		The script top level code should not output anything. Unexpected script
		outputs now emit warnings but in the future they may change to errors.
'@
		}
	)

	examples = @(
		@{code={
	## How to call Invoke-Build in order to deal with build failures.
	## Use one of the below techniques or you may miss some failures.

	## (1/2) If you do not want to catch errors and just want the calling
	## script to stop on build failures then

	$ErrorActionPreference = 'Stop'
	Invoke-Build ...

	## (2/2) If you want to catch build errors and proceed further depending
	## on them then use try/catch, $ErrorActionPreference does not matter:

	try {
		Invoke-Build ...
		# Build completed
	}
	catch {
		# Build FAILED, $_ is the error
	}

		}}

		@{code={
	# Invoke tasks Build and Test from the default script with parameters.
	# The script defines parameters Output and WarningLevel by param().

	Invoke-Build Build, Test -Output log.txt -WarningLevel 4
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
	# How to use build results, e.g. for summary

	try {
		# Invoke build and get the variable Result
		Invoke-Build -Result Result
	}
	finally {
		# Show build error
		"Build error: $(if ($Result.Error) {$Result.Error} else {'None'})"

		# Show task summary
		$Result.Tasks | Format-Table Elapsed, Name, Error -AutoSize
	}
		}}
	)

	links = @(
		@{ text = 'Wiki'; URI = 'https://github.com/nightroman/Invoke-Build/wiki' }
		@{ text = 'Project'; URI = 'https://github.com/nightroman/Invoke-Build' }
		# external
		@{ text = 'Build-Checkpoint' }
		@{ text = 'Build-Parallel' }
		# special
		@{ text = '' }
		@{ text = 'For other commands, at first invoke:' }
		@{ text = 'PS> . Invoke-Build' }
		@{ text = '' }
		# aliases
		@{ text = 'task      (Add-BuildTask)' }
		@{ text = 'exec      (Invoke-BuildExec)' }
		@{ text = 'assert    (Assert-Build)' }
		@{ text = 'equals    (Assert-BuildEquals)' }
		@{ text = 'remove    (Remove-BuildItem)' }
		@{ text = 'property  (Get-BuildProperty)' }
		@{ text = 'requires  (Test-BuildAsset)' }
		@{ text = 'use       (Use-BuildAlias)' }
		# functions
		@{ text = 'Confirm-Build' }
		@{ text = 'Get-BuildError' }
		@{ text = 'Get-BuildSynopsis' }
		@{ text = 'Resolve-MSBuild' }
		@{ text = 'Set-BuildFooter' }
		@{ text = 'Set-BuildHeader' }
		@{ text = 'Write-Build' }
	)
}

### Add-BuildTask
@{
	command = 'Add-BuildTask'
	synopsis = '(task) Defines and adds a task.'

	description = @'
	Scripts use its alias 'task'. It is normally used in the build script scope
	but it can be called from another script or function. Build scripts should
	have at least one task.

	This command is all that build scripts really need. Tasks are main build
	blocks. Other build commands are helpers, scripts do not have to use them.

	In addition to task parameters, you may use task help comments, synopses,
	preceding task definitions:

		# Synopsis: ...
		task ...

	Synopses are used in task help information returned by the command

		Invoke-Build ?

	To get a task synopsis during a build, use Get-BuildSynopsis.
'@

	parameters = @{
		Name = @'
		The task name. Wildcard characters are deprecated and "?" must not be
		the first character. Duplicated names are allowed, each added task
		overrides previously added with the same name.
'@
		Jobs = @'
		Specifies one or more task jobs or a hashtable with actual parameters.
		Jobs are other task references and own actions, script blocks. Any
		number of jobs is allowed. Jobs are invoked in the specified order.

		Valid jobs are:

			[string] - an existing task name, normal reference
			[string] "?Name" - safe reference to a task allowed to fail
			[scriptblock] - action, a script block invoked for this task

		Special value:

			[hashtable] which contains the actual task parameters in addition
			to the task name. This task definition is more convenient with
			complex parameters, often typical for incremental tasks.

			Example:
				task Name @{
					Inputs = {...}
					Outputs = {...}
					Partial = $true
					Jobs = {
						process {...}
					}
				}
'@
		After = @'
		Tells to add this task to the end of jobs of the specified tasks.

		Altered tasks are defined as normal references (TaskName) or safe
		references (?TaskName). In the latter case this inserted task may
		fail without stopping a build.

		Parameters After and Before are used in order to alter task jobs
		in special cases when direct changes in task source code are not
		suitable. Use Jobs in order to define relations in usual cases.
'@
		Before = @'
		Tells to insert this task to jobs of the specified tasks.
		It is inserted before the first action or added to the end.

		See After for details.
'@
		If = @{default = '$true'; description = @'
		Specifies the optional condition to be evaluated. If the condition
		evaluates to false then the task is not invoked. The condition is
		defined in one of two ways depending on the requirements.

		Using standard Boolean notation (parenthesis) the condition is checked
		once when the task is defined. A use case for this notation might be
		evaluating a script parameter or another sort of global condition.

			Example:
				task Task1 -If ($Param1 -eq ...) {...}
				task Task2 -If ($PSVersionTable.PSVersion.Major -ge 5) {...}

		Using script block notation (curly braces) the condition is evaluated
		on task invocation. If a task is referenced by several tasks then the
		condition is evaluated each time until it gets true and the task is
		invoked. The script block notation is normally used for a condition
		that may be defined or changed during the build or just expensive.

			Example:
				task SomeTask -If {...} {...}
'@}
		Inputs = @'
		Specifies the input items, tells to process the task as incremental,
		and requires the parameter Outputs with the optional switch Partial.

		Inputs are file items or paths or a script block which gets them.

		Outputs are file paths or a script block which gets them.
		A script block is invoked with input paths piped to it.

		Automatic variables for incremental task actions:

			$Inputs - full input paths, array of strings
			$Outputs - result of the evaluated Outputs

		With the switch Partial the task is processed as partial incremental.
		There must be one-to-one correspondence between Inputs and Outputs.

		Partial task actions often contain "process {}" blocks.
		Two more automatic variables are available for them:

			$_ - full path of an input item
			$2 - corresponding output path

		See also wiki topics about incremental tasks:
		https://github.com/nightroman/Invoke-Build/wiki
'@
		Outputs = @'
		Specifies the output paths of the incremental task, either directly on
		task creation or as a script block invoked with the task. It is used
		together with Inputs. See Inputs for details.
'@
		Partial = @'
		Tells to process the incremental task as partial incremental.
		It is used with Inputs and Outputs. See Inputs for details.
'@
		Data = @'
		Any object attached to the task. It is not used by the engine.
		When the task is invoked this object is available as $Task.Data.
'@
		Done = @'
		Specifies the command or a script block which is invoked after the
		task. Custom handlers should check for $Task.Error if it matters.
'@
		Source = @'
		Specifies the task source. It is used by wrapper functions in order to
		provide the actual source for location messages and synopsis comments.
'@
	}

	examples = @(
		### Job combinations
		@{
			code={
	# Dummy task with no jobs
	task Task1

	# Alias of another task
	task Task2 Task1

	# Combination of tasks
	task Task3 Task1, Task2

	# Simple action task
	task Task4 {
		# action
	}

	# Typical complex task: referenced task(s) and one own action
	task Task5 Task1, Task2, {
		# action after referenced tasks
	}

	# Possible complex task: actions and tasks in any required order
	task Task6 {
		# action before Task1
	},
	Task1, {
		# action after Task1 and before Task2
	},
	Task2
			}
			remarks = @'
	This example shows various possible combinations of task jobs.
'@
		}

		### Splatting helper
		@{
			code={
	# Synopsis: Complex task with parameters as a hashtable.
	task TestAndAnalyse @{
		If = !$SkipAnalyse
		Inputs = {
			Get-ChildItem . -Recurse -Include *.ps1, *.psm1
		}
		Outputs = {
			'Analyser.log'
		}
		Jobs = 'Test', {
			Invoke-ScriptAnalyzer . > Analyser.log
		}
	}

	# Synopsis: Simple task with usual parameters.
	task Test -If (!$SkipTest) {
		Invoke-Pester
	}
			}
			remarks = @'
	Tasks with complex parameters are often difficult to compose in a readable
	way. In such cases use a hashtable in order to specify task parameters in
	addition to the task name. Keys and values correspond to parameter names
	and values.
'@
		}
	)

	links = @(
		@{ text = 'Get-BuildError' }
		@{ text = 'Get-BuildSynopsis' }
		@{ URI = 'https://github.com/nightroman/Invoke-Build/wiki' }
	)
}

### Get-BuildError
@{
	command = 'Get-BuildError'
	synopsis = 'Gets the specified task error.'

	description = @'
	The specified task is usually safe referenced in the build (?name) and a
	caller (usually a downstream task) gets its potential error for analysis.
'@

	parameters = @{
		Task = @'
		Name of the task which error is requested.
'@
	}

	outputs = @(
		@{
			type = 'Error'
			description = 'An error or null if the task has not failed.'
		}
	)

	links = @(
		@{ text = 'Add-BuildTask' }
	)
}

### Assert-Build
@{
	command = 'Assert-Build'
	synopsis = '(assert) Checks for a condition.'

	description = @'
	Scripts use its alias 'assert'. This command checks for a condition and
	if it is not true throws an error with the default or specified message.
'@

	parameters = @{
		Condition = @'
		The condition.
'@
		Message = @'
		An optional message describing the assertion condition.
'@
	}

	links = @(
		@{ text = 'Assert-BuildEquals' }
	)
}

### Assert-BuildEquals
@{
	command = 'Assert-BuildEquals'
	synopsis = '(equals) Verifies that two specified objects are equal.'

	description = @'
	Scripts use its alias 'equals'. This command verifies that two specified
	objects are equal using [Object]::Equals(). If objects are not equal the
	command fails with a message showing object values and types.
'@

	parameters = @{
		A = 'The first object.'
		B = 'The second object.'
	}

	links = @(
		@{ text = 'Assert-Build' }
	)
}

### Get-BuildProperty
@{
	command = 'Get-BuildProperty'
	synopsis = '(property) Gets the session or environment variable or the default.'

	description = @'
	Scripts use its alias 'property'. The command returns:

		- session variable value if it is not $null or ''
		- environment variable if it is not $null or ''
		- default value if it is not $null
		- error
'@

	parameters = @{
		Name = @'
		Specifies the session or environment variable name.
'@
		Value = @'
		Specifies the default value. If it is omitted or null then the variable
		must exist with a not empty value. Otherwise an error is thrown.
'@
		Boolean = @'
		Treats values like 1 and 0 as $true and $false, including strings with
		extra spaces. Others are converted by [System.Convert]::ToBoolean().
'@
	}

	outputs = @(
		@{
			type = 'Object'
			description = 'Requested property value.'
		}
	)

	examples = @(
		@{code={
	# Inherit an existing value or throw an error

	$OutputPath = property OutputPath
		}}

		@{code={
	# Get an existing value or use the default

	$WarningLevel = property WarningLevel 4
		}}
	)

	links = @(
		@{ text = 'Test-BuildAsset' }
	)
}

### Get-BuildSynopsis
@{
	command = 'Get-BuildSynopsis'
	synopsis = 'Gets the task synopsis.'

	description = @'
	Gets the specified task synopsis if it is available.

	Task synopses are defined in preceding comments as

		# Synopsis: ...

	or

		<#
		.Synopsis
		...
		#>

	This function may be used in Set-BuildHeader for printing task synopses.
'@

	parameters = @{
		Task = @'
		The task object. During the build, the current task is available as the
		automatic variable $Task.
'@
		Hash = @'
		The cache used by external tools. Scripts may omit this parameter.
'@
	}

	outputs = @{
		type = 'String'
	}

	examples = @{code={
		# Headers: print task paths as usual and synopses in addition
		Set-BuildHeader {
			param($Path)
			Write-Build Cyan "Task $Path : $(Get-BuildSynopsis $Task)"
		}

		# Synopsis: This task prints its own synopsis.
		task Task1 {
			'My synopsis : ' + (Get-BuildSynopsis $Task)
		}
	}}

	links = @(
		@{ text = 'Set-BuildFooter' }
		@{ text = 'Set-BuildHeader' }
	)
}

### Get-BuildVersion
@{
	command = 'Get-BuildVersion'
	synopsis = 'Gets version string from file.'

	description = @'
	It finds the first file line matching Regex and returns its first capturing
	group string.
'@

	parameters = @{
		Path = @'
		The file with version strings, like change log, release notes, etc.
'@
		Regex = @'
		[string] or [regex] defining version as its first capturing group.
'@
	}

	outputs = @{
		type = 'String'
	}

	examples = @{code={
		# Get version from file
		Get-BuildVersion Release-Notes.md '##\s+v(\d+\.\d+\.\d+)'
	}}
}

### Invoke-BuildExec
@{
	command = 'Invoke-BuildExec'
	synopsis = '(exec) Invokes an application and checks $LastExitCode.'

	description = @'
	Scripts use its alias 'exec'. It invokes the script block which is supposed
	to call an executable. Then $LastExitCode is checked. If it does not match
	the specified codes (0 by default) an error is thrown.

	If you have any issues with standard error output of the invoked app, try
	using `exec` with -ErrorAction Continue, SilentlyContinue, or Ignore. This
	does not affect failures of `exec`, they still depend on the app exit code.
	This works around PowerShell standard errors issues.
'@

	parameters = @{
		Command = @'
		Command that invokes an executable which exit code is checked. It must
		invoke an application directly (.exe) or not (.cmd, .bat), otherwise
		$LastExitCode is not set and may contain the code of another command.
'@
		ExitCode = @{default = '@(0)'; description = @'
		Valid exit codes (e.g. 0..3 for robocopy).
'@}
		ErrorMessage = @'
		Specifies the text included to standard error messages.
'@
		Echo = @'
		Tells to write the command and its used variable values.
		WARNING: With echo you may expose sensitive information.
'@
		StdErr = @'
		Tells to set $ErrorActionPreference to Continue, capture all output and
		write as strings. Then, if the exit code is failure, add the standard
		error output text to the error message.
'@
	}

	outputs = @(
		@{
			type = 'Objects'
			description = @'
		Output of the specified command.
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
		@{ text = 'Use-BuildEnv' }
	)
}

### Remove-BuildItem
@{
	command = 'Remove-BuildItem'
	synopsis = '(remove) Removes specified items.'

	description = @'
	Scripts use its alias 'remove'. This command removes existing items,
	ignores missing items, and fails if it cannot remove existing items.

	Use the switch Verbose in order to output messages about removing
	existing and skipping missing items or patterns specified by Path.
'@

	parameters = @{
		Path = @{
			wildcard = $true
			description = @'
		Specifies the items to be removed. Wildcards are allowed.
		The parameter is mostly the same as Path of Remove-Item.
		For sanity, paths with only ., *, \, / are not allowed.
'@
		}
	}

	examples = @(
		@{code={
	# Remove some temporary items

	remove bin, obj, *.test.log
		}}
	)
}

### Set-BuildFooter
@{
	command = 'Set-BuildFooter'
	synopsis = 'Tells how to write task footers.'

	description = @'
	This build block is used in order to change the default task footer format.
	Use the automatic variable $Task in order to get the current task data.
	Use Write-Build in order to write with colors.
'@

	parameters = @{
		Script = @'
		The script like {param($Path) ...} which is used in order to write task
		footers. The parameter Path includes the parent and current task names.

		In order to omit task footers, set an empty block:

			Set-BuildFooter {}
'@
	}

	examples = @{code={
		# Use the usual footer format but change the color
		Set-BuildFooter {
			param($Path)
			Write-Build DarkGray "Done $Path $($Task.Elapsed)"
		}

		# Synopsis: Data for footers in addition to $Path and $Task.Elapsed
		task Task1 {
			'Task name     : ' + $Task.Name
			'Start time    : ' + $Task.Started
			'Location path : ' + $Task.InvocationInfo.ScriptName
			'Location line : ' + $Task.InvocationInfo.ScriptLineNumber
		}
	}}

	links = @(
		@{ text = 'Get-BuildSynopsis' }
		@{ text = 'Set-BuildHeader' }
		@{ text = 'Write-Build' }
	)
}

### Set-BuildHeader
@{
	command = 'Set-BuildHeader'
	synopsis = 'Tells how to write task headers.'

	description = @'
	This build block is used in order to change the default task header format.
	Use the automatic variable $Task in order to get the current task data.
	Use Write-Build in order to write with colors.
'@

	parameters = @{
		Script = @'
		The script like {param($Path) ...} which is used in order to write task
		headers. The parameter Path includes the parent and current task names.
'@
	}

	examples = @{code={
		# Headers: write task paths as usual and synopses in addition
		Set-BuildHeader {
			param($Path)
			Write-Build Cyan "Task $Path --- $(Get-BuildSynopsis $Task)"
		}

		# Synopsis: Data for headers in addition to $Path and Get-BuildSynopsis
		task Task1 {
			'Task name     : ' + $Task.Name
			'Start time    : ' + $Task.Started
			'Location path : ' + $Task.InvocationInfo.ScriptName
			'Location line : ' + $Task.InvocationInfo.ScriptLineNumber
		}
	}}

	links = @(
		@{ text = 'Get-BuildSynopsis' }
		@{ text = 'Set-BuildFooter' }
		@{ text = 'Write-Build' }
	)
}

### Test-BuildAsset
@{
	command = 'Test-BuildAsset'
	synopsis = '(requires) Checks for required build assets.'

	description = @'
	Scripts use its alias 'requires'. This command tests the specified assets.
	It fails if any is missing. It is used in script code (common assets) and
	in tasks (individual assets).
'@

	parameters = @{
		Variable = @'
		Specifies the required session variable names and tells to fail if a
		variable is missing or its value is null or empty string.
'@
		Environment = @'
		Specifies the required environment variable names.
'@
		Path = @'
		Specifies literal paths to be tested by Test-Path. If the specified
		expression uses required assets then test these assets first by a
		separate command.
'@
		Property = @'
		Specifies session or environment variable names and tells to fail if a
		variable is missing or its value is null or empty string.
'@
	}

	links = @(
		@{ text = 'Get-BuildProperty' }
	)
}

### Use-BuildAlias
@{
	command = 'Use-BuildAlias'
	synopsis = '(use) Sets framework or directory tool aliases.'

	description = @'
	Scripts use its alias 'use'. Invoke-Build does not change the system path
	in order to make framework tools available by names. This is not suitable
	for using mixed framework tools (in different tasks, scripts, parallel
	builds). Instead, this function is used for setting tool aliases in the
	scope where it is called.

	This command may be used in the script scope to make aliases for all tasks.
	But it can be called from tasks in order to use more task specific tools.
'@

	parameters = @{
		Path = @'
		Specifies the tools directory.

		If it is * or it starts with digits followed by a dot then the MSBuild
		path is resolved using the package script Resolve-MSBuild.ps1. Build
		scripts may invoke it directly by the provided alias Resolve-MSBuild.
		The optional suffix x86 tells to use 32-bit MSBuild.

			For just MSBuild use Resolve-MSBuild instead:

				Set-Alias MSBuild (Resolve-MSBuild ...)
				MSBuild ...

			or

				$MSBuild = Resolve-MSBuild ...
				& $MSBuild ...

		If it is like Framework* then it is assumed to be a path relative to
		Microsoft.NET in the Windows directory.

		Otherwise it is a full or relative literal path of any directory.

		Examples: *, 4.0, Framework\v4.0.30319, .\Tools
'@
		Name = @'
		Specifies the tool names. They become aliases in the current scope.
		If it is a build script then the aliases are created for all tasks.
		If it is a task then the aliases are available just for this task.
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
		@{ text = 'Resolve-MSBuild' }
	)
}

### Confirm-Build
@{
	command = 'Confirm-Build'
	synopsis = 'Prompts to confirm an operation.'

	description = @'
	This function prints the prompt and options: [Y] Yes [N] No [S] Suspend.
	Choose Y to continue or N to skip. [S] enters the nested prompt, you may
	invoke some commands end then `exit`.

	Confirm-Build must not be called during non interactive builds. Scripts
	should take care of this. For example, add the switch $Quiet and define
	Confirm-Build as "Yes to All":

		if ($Quiet) {function Confirm-Build {$true}}
'@

	parameters = @{
		Query = @'
The confirmation query.
If it is omitted or empty, "Continue with this operation?" is used.
'@
		Caption = @'
The confirmation caption.
If it is omitted, the current task or script name is used.
'@
	}

	outputs = @{
		type = 'Boolean'
	}
}

### Write-Build
@{
	command = 'Write-Build'
	synopsis = 'Writes text using colors if they are supported.'

	description = @'
	This function is used in order to output colored text in a console or other
	hosts with colors. Unlike Write-Host it is suitable for redirected output.

	Write-Build is designed for tasks and build blocks, not script functions.

	With PowerShell 7.2+ and $PSStyle.OutputRendering ANSI, Write-Build uses
	ANSI escape sequences.
'@

	parameters = @{
		Color = @{
			required = $true
			description = '[System.ConsoleColor] value or its string representation.'
		}
		Text = @{
			required = $true
			description = 'Text written using colors if they are supported.'
		}
	}

	outputs = @{
		type = 'String'
	}
}

### Use-BuildEnv
@{
	command = 'Use-BuildEnv'
	synopsis = 'Invokes script with temporary changed environment variables.'

	description = @'
	This command sets the specified environment variables and invokes the
	script. Then it restores the original values of specified variables.
'@

	parameters = @{
		Env = @'
		The hashtable of environment variables used by the script.
		Keys and values correspond to variable names and values.
'@
		Script = @'
		The script invoked with the specified variables.
'@
	}

	outputs = @{
		type = 'Objects'
		description = 'Output of the specified script.'
	}

	examples = @(
		@{code={
			# Invoke with temporary changed Port and Path
			Use-BuildEnv @{
				Port = '9780'
				Path = "$PSScriptRoot\Scripts;$env:Path"
			} {
				exec { dotnet test }
			}
		}}
	)

	links = @(
		@{ text = 'Invoke-BuildExec' }
	)
}

### Build-Parallel.ps1
@{
	command = 'Build-Parallel.ps1'
	synopsis = 'Invokes parallel builds by Invoke-Build'

	description = @'
	This script invokes several build scripts simultaneously by Invoke-Build.
	Number of parallel builds is set to the number of processors by default.

	NOTE: Avoid using Build-Parallel in scenarios with PowerShell classes.
	Known issues: https://github.com/nightroman/Invoke-Build/issues/180

	VERBOSE STREAM

	Verbose messages are propagated to the caller if Verbose is set to true in
	build parameters. They are written all together before the build output.

		Build-Parallel @(
			@{File=...; Task=...; Verbose=$true}
			...
		)

	INFORMATION STREAM

	Information messages are propagated to the caller if InformationAction is
	set to Continue in build parameters. They are written all together before
	the build output.

		Build-Parallel @(
			@{File=...; Task=...; InformationAction='Continue'}
			...
		)

	In addition or instead, information messages are collected in the variable
	specified by InformationVariable in build parameters.

		Build-Parallel @(
			@{File=...; Task=...; InformationVariable='info'}
			...
		)

		# information messages
		$info
'@

	parameters = @{
		Build = @'
		Build parameters defined as hashtables with these keys/data:

			Task, File, ... - Invoke-Build.ps1 and script parameters
			Log - Tells to write build output to the specified file

		Any number of builds is allowed, including 0 and 1. The maximum number
		of parallel builds is the number of processors by default. It can be
		changed by the parameter MaximumBuilds.
'@
		Result = @'
		Tells to output build results using a variable. It is either a name of
		variable to be created for results or any object with the property
		Value to be assigned ([ref], [hashtable]).

		Result properties:

			Tasks - tasks (*)
			Errors - errors (*)
			Warnings - warnings (*)
			Started - start time
			Elapsed - build duration

		(*) see: help Invoke-Build -Parameter Result
'@
		Timeout = @'
		Maximum overall build time in milliseconds.
'@
		MaximumBuilds = @{default = 'Number of processors.'; description = @'
		Maximum number of builds invoked at the same time.
'@}
		FailHard = @'
		Tells to abort all builds if any build fails.
'@
		ShowParameter = @'
		Tells to show the specified parameter values in build titles.
'@
	}

	outputs = @{
		type = 'Text'
		description = 'Output of invoked builds and other log messages.'
	}

	examples = @(
		@{
			code = {
	Build-Parallel @(
		@{File='Project1.build.ps1'}
		@{File='Project2.build.ps1'; Task='MakeHelp'}
		@{File='Project2.build.ps1'; Task='Build', 'Test'}
		@{File='Project3.build.ps1'; Log='C:\TEMP\Project3.log'}
		@{File='Project4.build.ps1'; Configuration='Release'}
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

### Build-Checkpoint.ps1
@{
	command = 'Build-Checkpoint.ps1'
	synopsis = 'Invokes persistent builds with checkpoints.'
	description = @'
	This command invokes the build and saves build state checkpoints after each
	completed task. If the build is interrupted then it may be resumed later
	with the saved checkpoint file.

	The built-in Export-Clixml and Import-Clixml are used for saving checkpoints.
	Keep in mind that not all data types are suitable for this serialization.

	CUSTOM EXPORT AND IMPORT

	By default, the command saves and restores build tasks, script path, and
	all parameters declared by the build script. Tip: consider declaring some
	script variables as artificial parameters in order to make them persistent.

	If this is not enough for saving and restoring the build state then use
	custom export and import blocks. The export block is called on writing
	checkpoints, i.e. on each task. The import block is called on resuming
	once, before the task to be resumed.

	The export block is set by `Set-BuildData Checkpoint.Export`, e.g.

		Set-BuildData Checkpoint.Export {
			$script:var1
			$script:var2
		}

	The import block is set by `Set-BuildData Checkpoint.Import`, e.g.

		Set-BuildData Checkpoint.Import {
			param($data)
			$var1, $var2 = $data
		}

	The import block is called in the script scope. Thus, $var1 and $var2 are
	script variables right away. We may but do not have to use the prefix.

	The parameter $data is the output of Checkpoint.Export exported to clixml
	and then imported from clixml.

	OMITTED OR SCRIPT CHECKPOINT

	Omitted or script Checkpoint and no other parameters is the special
	case. The engine builds all tasks of the default or specified script
	with checkpoints.

	The checkpoint path is the script path with added ".clixml". The persistent
	build starts if the checkpoint does not exist, otherwise resumes with the
	existing checkpoint.
'@
	parameters = @{
		Checkpoint = @'
		Specifies the checkpoint file (clixml). The checkpoint file is removed
		after successful builds unless the switch Preserve is specified.

		See DESCRIPTION / OMITTED OR SCRIPT CHECKPOINT for the special case.
'@
		Build = @'
		Specifies the build and script parameters. WhatIf is not supported.

		When the build resumes by Resume or Auto then fields Task, File, and
		script parameters are ignored and restored from the checkpoint file.
		But fields Result, Safe, Summary are used as usual build parameters.
'@
		Preserve = @'
		Tells to preserve the checkpoint file on successful builds.
'@
		Resume = @'
		Tells to resume the build from the existing checkpoint file.
'@
		Auto = @'
		Tells to start a new build if the checkpoint file is not found or
		resume the build from the found checkpoint file.
'@
	}
	outputs = @{
		type = 'Text'
		description = 'Output of the invoked build.'
	}
	examples = @(
		@{code={
	# Invoke a persistent sequence of steps defined as tasks.
	Build-Checkpoint temp.clixml @{Task = '*'; File = 'Steps.build.ps1'}

	# Given the above failed, resume at the failed step.
	Build-Checkpoint temp.clixml -Resume
		}}
	)
	links = @(
		@{ text = 'Invoke-Build' }
	)
}
