
#Requires -Version 3.0

<#
.Synopsis
	Converts psake build scripts to Invoke-Build.
	Invoke-Build - Build Automation in PowerShell
	Copyright (c) 2011-2016 Roman Kuzmin

.Description
	The script converts the specified psake script to Invoke-Build script code.
	In order to save the code to a file, use Set-Content, for example:

		Convert-psake default.ps1 | Set-Content .build.ps1 [-Encoding ...]

	The converted script should be reviewed before using it. Task actions are
	copied as they are without conversion. $psake, "assert", "exec", and other
	features may have to be adjusted manually. See also "TODO" comments added
	to the result script.

	SCRIPT CONVERTION SCHEME AND GUIDELINES

	COMMANDS (mostly done automatically)

	task -> task
		"default" -> "."
		Properties
			Properties are defined as script parameters and script variables
			and used in tasks as $VarName/$script:VarName for reading/writing.
		Parameters
			Name -> Name
				"-Name" is normally omitted.
			Depends, PreAction, Action, PostAction -> Jobs
				"-Jobs" is normally omitted.
				Comma separated list of referenced tasks and actions.
				Tasks may be safe-referenced as (job TaskName -Safe).
			PreCondition -> If
				"If" also accepts values evaluated at creation.
			PostCondition ->
				Use an extra action with assert in Jobs: ..., {assert ...}
			ContinueOnError ->
				Use (job TaskName -Safe) in parent tasks.
			RequiredVariables ->
				Use "$VarName = property VarName" in the action.
			Description ->
				Use help comments: # Synopsis: ...
			Alias ->
				Use another task: task Alias TaskName

	properties ->
		Simply copy the code from "properties" to the script scope.
		Consider to move variables to "param()" to use as parameters.

	include ->
		Simply dot-source (.) or invoke (&) a script to be included.

	framework -> use
		Parameters
			Framework -> Path
				A tools version or Framework\X in $env:windir\Microsoft.NET
				or any tool directory path. "-Path" is normally omitted.
			-> Name
				"-Name" is normally omitted.
				Tool names used as script scope aliases.

		Example:
			old: framework 4.0
			new: use 4.0 MSBuild [, csc, ...]

	assert -> assert
		Parameters
	        ConditionToCheck -> Condition
	        	"-Condition" is normally omitted.
	        FailureMessage -> Message (optional)
	        	"-Message" may be omitted.

	exec -> exec
		Parameters
			Cmd -> Command
				"-Command" is normally omitted.
			-> ExitCode (optional), valid codes, e.g. (0..3) for robocopy
				"-ExitCode" may be omitted.
			ErrorMessage, MaxRetries, RetryTriggerErrorPattern ->
				Not supported.

	TaskSetup -> Enter-BuildTask
		Define the function Enter-BuildTask in the script and copy the code.

	TaskTearDown -> Exit-BuildTask
		Define the function Exit-BuildTask in the script. Unlike TaskTearDown,
		Exit-BuildTask is always called if its pair Enter-BuildTask is called.

	FormatTaskName ->
		Not supported. This feature can be added on a request.
		Use functions Enter|Exit-BuildTask for extra task headers and footers.


	VARIABLES (should be done manually)

	Make sure scripts do not use variables $BuildRoot, $BuildFile, $BuildTask.
	If they do then rename them first. Then convert $psake data:

	$psake.build_script_dir
		-> $BuildRoot

	$psake.build_script_file
		-> $BuildFile, if actually its path is needed in the context
		-> (Get-Item -LiteralPath $BuildFile), if the item is needed

	$psake.version
		-> Get-BuildVersion

	$psake.<other>
		-> Not supported.

.Parameter Source
		Specifies the psake script to be converted. The script is not invoked
		by default. Normally this is not needed, simple parsing is enough. In
		special cases use the switch Invoke.
.Parameter Invoke
		Tells to invoke the script before conversion. This may be needed if
		some names or objects are defined dynamically in the script.
.Parameter Synopsis
		Tells to add "# Synopsis:" even for tasks with no Description.

.Outputs
	Converted code. Save it to a file by redirecting to Set-Content. Use of ">"
	or "Out-File" is not recommended due to potentially breaking line wrapping.

.Example
	Convert-psake default.ps1 | Set-Content .build.ps1
	Simple conversion with default options.

.Example
	Convert-psake default.ps1 -Invoke -Synopsis | Set-Content .build.ps1 -Encoding UTF8
	This command uses some options.

.Link
	https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-psake
#>

param(
	[Parameter(Mandatory=1)][string]$Source,
	[switch]$Invoke,
	[switch]$Synopsis
)

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

### Source

$Source = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Source)
if (![System.IO.File]::Exists($Source)) {throw "Missing Source file: '$Source'."}
${*Source} = $Source
${*Invoke} = $Invoke
${*Synopsis} = $Synopsis
Remove-Variable Source, Invoke, Synopsis

### Dot-source with dummy tools
if (${*Invoke}) {
	function Invoke-Dummy {}
	Set-Alias properties Invoke-Dummy
	Set-Alias framework Invoke-Dummy
	Set-Alias include Invoke-Dummy
	Set-Alias TaskSetup Invoke-Dummy
	Set-Alias TaskTearDown Invoke-Dummy
	Set-Alias exec Invoke-Dummy
	Set-Alias task Invoke-Dummy
	$null = . ${*Source}
}

### Redefine tools

Set-Alias properties Write-Property
Set-Alias framework Write-Framework
Set-Alias include Write-Include
Set-Alias TaskSetup Write-TaskSetup
Set-Alias TaskTearDown Write-TaskTearDown
Set-Alias task Write-Task

function Write-Property([scriptblock]$properties) {
	'# TODO: Move some properties to script param() in order to use as parameters.'
	$properties
}

function Write-Framework([string]$framework) {
	'# TODO: Specify used tool names exactly as they are used in the script.'
	'# MSBuild is an example. It should be used as MSBuild, not MSBuild.exe'
	'# Example with more tools: use 4.0 MSBuild, csc, ngen'
	if ($framework -notmatch '^\d+\.\d+$') {
		"# TODO: The form '$framework' is not supported. See help:"
		'# . Invoke-Build; help -full Use-BuildAlias'
	}
	"use $framework MSBuild"
}

function Write-Include([string]$fileNamePathToInclude) {
	'# TODO: Decide whether it is dot-sourced (.) or just invoked (&).'
	". '$($fileNamePathToInclude.Replace("'", "''"))'"
}

function Write-TaskSetup([scriptblock]$setup) {
	"function Enter-BuildTask {$setup}"
}

function Write-TaskTearDown([scriptblock]$teardown) {
	"function Exit-BuildTask {$teardown}"
}

function Write-Task
{
	param(
		[string]$name,
		[scriptblock]$action,
		[scriptblock]$preaction,
		[scriptblock]$postaction,
		[scriptblock]$precondition,
		[scriptblock]$postcondition,
		[switch]$continueOnError,
		[string[]]$depends,
		[string[]]$requiredVariables,
		[string]$description,
		[string]$alias
	)

	if ($description -or ${*Synopsis}) {
		$description = $description -replace '[\r\n]+', ' '
		"# Synopsis: $description"
	}

	if ($alias) {"# TODO: Alias '$alias' is not supported. Do not use it or define another task: task $alias $($name)"}
	if ($continueOnError) {"# TODO: ContinueOnError is not supported. Instead, in parent tasks use references: (job $name -Safe)"}
	if ($requiredVariables) {'# TODO: RequiredVariables is not supported. Instead, in the action use: $VarName = property VarName'}

	### task Name
	$$ = 'task '
	if ($name -eq 'default') {
		'# TODO: Default task. If it is the first then any name can be used instead.'
		$$ += '.'
	}
	else {
		$$ += $name
	}

	### If
	if ($precondition) {
		$$ += " -If {$precondition}"
	}

	$comma = $false

	### Referenced tasks
	if ($depends) {
		$$ += ' ' + ($depends -join ', ')
		$comma = $true
	}

	### Preaction
	if ($preaction) {
		if ($comma) {$$ += ','} else {$comma = $true}
		$$ += " {$preaction}"
	}

	### Action
	if ($action) {
		if ($comma) {$$ += ','} else {$comma = $true}
		$$ += " {$action}"
	}

	### Postaction
	if ($postaction) {
		if ($comma) {$$ += ','} else {$comma = $true}
		$$ += " {$postaction}"
	}

	### Postcondition
	if ($postcondition) {
		if ($comma) {$$ += ','}
		$$ += " { assert `$($postcondition) }"
	}

	$$
}

### Main

$warnings = @()
$out = New-Object System.Text.StringBuilder
function Add-Text($Text) {$null = $out.Append($Text)}
function Add-Line($Text) {$null = $out.AppendLine($Text)}

Add-Line @'
<#
.Synopsis
	Build script invoked by Invoke-Build.

.Description
	TODO: Declare build parameters as standard script parameters. Parameters
	are specified directly for Invoke-Build if their names do not conflict.
	Otherwise or alternatively they are passed in as "-Parameters @{...}".
#>

# TODO: [CmdletBinding()] is optional but recommended for strict name checks.
[CmdletBinding()]
param(
)
'@

$content = Get-Content -LiteralPath ${*Source}
$tokens = @([System.Management.Automation.PSParser]::Tokenize($content, [ref]$null))
$statements = @([scriptblock]::Create(($content | Out-String -Width 1mb)).Ast.EndBlock.Statements)

$iToken = 0
foreach($statement in $statements) {
	$extent = $statement.Extent

	# out previous tokens
	while($iToken -lt $tokens.Count) {
		$token = $tokens[$iToken]
		if ($token.Start -ge $extent.StartOffset) {
			break
		}
		if ($token.Type -eq 'NewLine' -or $token.Type -eq 'Comment') {
			Add-Text $token.Content
		}
		++$iToken
	}

	# skip statement tokens
	while($iToken -lt $tokens.Count -and $tokens[$iToken].Start -lt $extent.EndOffset) {
		++$iToken
	}

	# out statement
	$text = $extent.Text
	if ($statement -is [System.Management.Automation.Language.PipelineAst]) {
		if ($text -match '^(properties|framework|include|TaskSetup|TaskTearDown|task)\b') {
			try {
				$text = (& ([scriptblock]::Create($text)) | Out-String -Width 1mb).Trim()
			}
			catch {
				$warnings += ('Conversion error at line {0}: {1}' -f $statement.Extent.StartLineNumber, $_)
				$text = @"
<# TODO: This statement was copied not converted due to the error:
$_
#>
$text
"@
			}
		}
	}
	Add-Text $text
}
$out.ToString()

foreach($warning in $warnings) {
	Write-Warning $warning
}
