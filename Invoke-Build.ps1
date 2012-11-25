
<#
Invoke-Build - Build Automation in PowerShell
Copyright (c) 2011-2012 Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#>

#.ExternalHelp Invoke-Build.ps1-Help.xml
param
(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][hashtable]$Parameters,
	[string]$Checkpoint,
	[hashtable]$Hook,
	$Result,
	[switch]$Safe,
	[switch]$WhatIf
)

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildVersion {[System.Version]'1.5.1'}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Add-BuildTask {
	[CmdletBinding(DefaultParameterSetName='.')]
	param
	(
		[Parameter(Position=0, Mandatory=$true)][string]$Name,
		[Parameter(Position=1)][object[]]$Jobs,
		$If = $true,
		[object[]]$After,
		[object[]]$Before,
		[Parameter(ParameterSetName='Incremental')][hashtable]$Incremental,
		[Parameter(ParameterSetName='Partial')][hashtable]$Partial
	)
	try {
		$t = $BuildList[$Name]
		if ($t) {throw *Fix 'Task name already exists:' $t}

		$t = Select-Object Name, Error, Started, Elapsed, Jobs, Try, If, Inputs, Outputs, Partial, After, Before, InvocationInfo -InputObject 1
		$t.Name = $Name
		$t.Jobs = $jobList = [System.Collections.ArrayList]@()
		$t.Try = $tryList = [System.Collections.ArrayList]@()
		$t.If = $If
		$t.After = $After
		$t.Before = $Before
		$t.InvocationInfo = $MyInvocation
		$BuildList.Add($Name, $t)

		switch($PSCmdlet.ParameterSetName) {
			Incremental {
				$t.Inputs, $t.Outputs = *KV $Incremental
			}
			Partial {
				$t.Inputs, $t.Outputs = *KV $Partial
				$t.Partial = $true
			}
		}

		if ($Jobs) { foreach($_ in $Jobs) { foreach($_ in $_) {
			$r, $d = *TD $_
			if ($d) {
				$null = $jobList.Add($r)
				if (1 -eq $d) {
					$null = $tryList.Add($r)
				}
			}
			elseif ($_ -is [string] -or $_ -is [scriptblock]) {
				$null = $jobList.Add($_)
			}
			else {throw "Invalid job type."}
		}}}
	}
	catch {*Die "Task '$Name': $_" InvalidArgument}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildError([Parameter(Mandatory=$true)][string]$Task) {
	$_ = $BuildList[$Task]
	if (!$_) {*Die "Task '$Task' is not defined." ObjectNotFound}
	$_.Error
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildProperty([Parameter(Mandatory=$true)][string]$Name, $Value) {
	$_ = $PSCmdlet.GetVariableValue($Name)
	if ($null -eq $_) {
		$_ = [System.Environment]::GetEnvironmentVariable($Name)
		if ($null -eq $_) {
			if ($null -eq $Value) {*Die "PowerShell or environment variable '$Name' is not defined." ObjectNotFound}
			$_ = $Value
		}
	}
	$_
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Assert-BuildTrue([Parameter()]$Condition, [string]$Message) {
	if (!$Condition) {*Die $(if ($Message) {"Assertion failed: $Message"} else {'Assertion failed.'}) InvalidOperation}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Invoke-BuildExec([Parameter(Mandatory=$true)][scriptblock]$Command, [int[]]$ExitCode=0) {
	${private:-c}, ${private:-x} = $Command, $ExitCode
	Remove-Variable Command, ExitCode
	. ${-c}
	if (${-x} -notcontains $LastExitCode) {*Die "Command {${-c}} exited with code $LastExitCode." InvalidResult}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Use-BuildAlias([Parameter()][string]$Path, [Parameter(Mandatory=$true)][string[]]$Name) {
	if ($Path) {
		try {
			$dir = if ($Path.StartsWith('Framework', [System.StringComparison]::OrdinalIgnoreCase)) {
				"$env:windir\Microsoft.NET\$Path"
			}
			else {
				$PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
			}
			if (![System.IO.Directory]::Exists($dir)) {throw "Directory does not exist: '$dir'."}
		}
		catch {*Die $_ InvalidArgument}
	}
	else {
		$dir = [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
	}

	foreach($_ in $Name) {
		Set-Alias $_ (Join-Path $dir $_) -Scope 1
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Write-BuildText([System.ConsoleColor]$Color, [string]$Text) {
	$_ = $Host.UI.RawUI.ForegroundColor
	try {
		$Host.UI.RawUI.ForegroundColor = $Color
		$Text
	}
	finally {
		$Host.UI.RawUI.ForegroundColor = $_
	}
}

#.ExternalHelp Invoke-Build.ps1-Help.xml
function Get-BuildFile($Path) {
	$f = [System.IO.Directory]::GetFiles($Path, '*.build.ps1')
	if ($f.Count -eq 1) {
		$f
	}
	else {
		foreach($_ in $f) { if ([System.IO.Path]::GetFileName($_) -eq '.build.ps1') {return $_} }
	}
}

if ($MyInvocation.InvocationName -eq '.') {
	"Invoke-Build.ps1 Version $(Get-BuildVersion)`r`nCopyright (c) 2011-2012 Roman Kuzmin"
	'Add-BuildTask','Use-BuildAlias','Invoke-BuildExec','Assert-BuildTrue','Get-BuildProperty','Get-BuildError','Get-BuildVersion','Write-BuildText' |
	.{process{ Get-Help $_}} | Format-Table Name, Synopsis -AutoSize | Out-String
	return
}

if ($Host.Name -eq 'Default Host' -or $Host.Name -eq 'ServerRemoteHost' -or !$Host.UI -or !$Host.UI.RawUI) {
	function Write-BuildText([System.ConsoleColor]$Color, [string]$Text) {$Text}
}

function Write-Warning([string]$Message) {
	Microsoft.PowerShell.Utility\Write-Warning $Message
	$_ = "WARNING: " + $Message
	++$BuildInfo.WarningCount
	++$BuildInfo.AllWarningCount
	$null = $BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
}

function *Fix($Text, $II) {"$Text`r`n$(*II $II)"}
function *Hook { if ($args[0]) { $_ = $args[0][$args[1]]; if ($_) {& $_} } }
function *II($_) {$_ = $_.InvocationInfo.PositionMessage; if ($_.StartsWith("`n")) {$_.Trim().Replace("`n", "`r`n")} else {$_}}
function *KV($_) {if ($_.Count -ne 1) {throw "Invalid pair, expected hashtable @{X = Y}."}; $_.Keys; $_.Values}
function *My {$_.InvocationInfo.ScriptName -like '*\Invoke-Build.ps1'}
function *TD($_) {if ($_ -is [hashtable]) {*KV $_} else {$_}}

function *Die([string]$Message, [System.Management.Automation.ErrorCategory]$Category = 0) {
	$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]$Message), $null, $Category, $null))
}

function *Alter($Add, $Tasks, [switch]$After) {
	foreach($_ in $Tasks) {
		$r, $d = *TD $_
		$t = $BuildList[$r]
		if (!$t) {throw "Task '$r' is not defined."}

		$j = $t.Jobs
		$n = $j.Count
		if ($After) {
			for($1 = $n - 1; $1 -ge 0; --$1) {
				if ($j[$1] -is [scriptblock]) {
					$n = $1 + 1
					break
				}
			}
		}
		else {
			for($1 = 0; $1 -lt $n; ++$1) {
				if ($j[$1] -is [scriptblock]) {
					$n = $1
					break
				}
			}
		}

		$j.Insert($n, $Add)
		if (1 -eq $d) {
			$null = $t.Try.Add($Add)
		}
	}
}

function *IO($Task) {
	${private:-t} = $Task
	Remove-Variable Task

	${private:-i} = ${-t}.Inputs
	if (${-i} -is [scriptblock]) {
		${-i} = @(*Do ${-i})
	}

	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	${private:-p} = [System.Collections.ArrayList]@()
	${-i} = foreach(${private:-} in ${-i}) {
		if (${-} -isnot [System.IO.FileInfo]) {
			${-} = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath(${-})
			if (!${-}.Exists) {throw "Input file does not exist: '${-}'."}
		}
		$null = ${-p}.Add(${-}.FullName)
		${-}
	}

	if (!${-p}) {
		return 'Skipping because there is no input.'
	}

	if (${-t}.Partial) {
		${private:-o} = @(if (${-t}.Outputs -is [scriptblock]) {
			Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
			${-p} | & ${-t}.Outputs
		}
		else {
			${-t}.Outputs
		})
		if (${-p}.Count -ne ${-o}.Count) {throw "Different input and output counts: $(${-p}.Count) and $(${-o}.Count)."}

		$1 = -1
		$i2 = [System.Collections.ArrayList]@()
		$o2 = [System.Collections.ArrayList]@()
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${-i}) {
			++$1
			$path = ${-o}[$1]
			$file = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($path)
			if (!$file.Exists -or $_.LastWriteTime -gt $file.LastWriteTime) {
				$null = $i2.Add(${-p}[$1]), $o2.Add($path)
			}
		}

		if ($i2) {
			${-t}.Inputs = $i2
			${-t}.Outputs = $o2
			return
		}
	}
	else {
		${-t}.Inputs = ${-p}

		if (${-t}.Outputs -is [scriptblock]) {
			${-t}.Outputs = *Do ${-t}.Outputs
			if (!${-t}.Outputs) {throw 'Incremental output cannot be empty.'}
		}

		$m = (${-i} | .{process{ $_.LastWriteTime.Ticks }} | Measure-Object -Maximum).Maximum
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		foreach($_ in ${-t}.Outputs) {
			$_ = [System.IO.FileInfo]$PSCmdlet.GetUnresolvedProviderPathFromPSPath($_)
			if (!$_.Exists -or $_.LastWriteTime.Ticks -lt $m) {return}
		}
	}
	'Skipping because all outputs are up-to-date with respect to the inputs.'
}

function *Task($Name, $Path) {
	${private:-t} = $BuildList[$Name]
	${private:-p} = if ($Path) {"$Path/$(${-t}.Name)"} else {${-t}.Name}
	if (${-t}.Error) {
		Write-BuildText DarkGray "${-p} failed."
		return
	}
	if (${-t}.Elapsed) {
		Write-BuildText DarkGray "Done ${-p}"
		return
	}
	Remove-Variable Name, Path

	${private:-if} = ${-t}.If
	if (${-if} -is [scriptblock]) {
		try {
			${-if} = *Do ${-if}
		}
		catch {
			${-t}.Error = $_
			throw
		}
	}
	if (!${-if}) {
		Write-BuildText DarkGray "${-p} skipped."
		return
	}

	${-t}.Started = [System.DateTime]::Now
	${private:-n} = 0
	${private:-io} = $null -ne ${-t}.Inputs
	${private:-skip} = $false

	try {
		. *Do Enter-BuildTask ${-t}
		foreach(${private:-j} in ${-t}.Jobs) {
			++${-n}
			if (${-j} -is [string]) {
				try {
					*Task ${-j} ${-p}
				}
				catch {
					if (${-t}.Try -notcontains ${-j}) {throw}
					foreach($t in $BuildTask) {
						$w = *TryTask $t ${-j}
						if ($w) {
							Write-BuildText Red $w
							throw
						}
					}
					Write-BuildText Red (*Fix "ERROR: $_" $_)
				}
			}
			else {
				${private:-log} = "${-p} (${-n}/$(${-t}.Jobs.Count))"
				Write-BuildText DarkYellow "${-log}:"

				if ($WhatIf) {
					${-j}
					continue
				}

				if (${-io}) {
					${-io} = $false
					${-skip} = *IO ${-t}
				}
				if (${-skip}) {
					Write-BuildText DarkYellow ${-skip}
					continue
				}

				try {
					. *Do Enter-BuildJob ${-t} ${-n}
					Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
					if ($null -eq ${-skip}) {
						$Inputs = ${-t}.Inputs
						$Outputs = ${-t}.Outputs
						if (${-t}.Partial) {
							${private:-} = 0
							$Inputs | .{process{
								$2 = $Outputs[${-}]
								++${-}
								$_
							}} | & ${-j}
						}
						else {
							$Inputs | & ${-j}
						}
					}
					else {
						& ${-j}
					}
				}
				catch {
					${-t}.Error = $_
					throw
				}
				finally {
					. *Do Exit-BuildJob ${-t} ${-n}
				}

				if (${-t}.Jobs.Count -ge 2) {
					Write-BuildText DarkYellow "Done ${-log}"
				}
			}
		}

		$_ = [System.DateTime]::Now - ${-t}.Started
		${-t}.Elapsed = $_
		Write-BuildText DarkYellow "Done ${-p} $_"

		if ($BuildInfo.Checkpoint) {
			Export-Clixml $BuildInfo.Checkpoint -InputObject $(
				, $BuildTask; $BuildFile; $BuildInfo.Parameters
				${private:-} = @{}
				foreach($_ in $BuildList.Values) {
					if ($_.Elapsed) {${-}.Add($_.Name, $_.Elapsed)}
				}
				${-}
				. *Do Export-Build
			)
		}
	}
	catch {
		${-t}.Elapsed = [System.DateTime]::Now - ${-t}.Started
		${-t}.Error = $_
		++$BuildInfo.ErrorCount
		++$BuildInfo.AllErrorCount
		$_ = if (*My) {"ERROR: Task '${-p}': $_"} else {*Fix "ERROR: Task '${-p}': $_" $_}
		$null = $BuildInfo.Messages.Add($_), $BuildInfo.AllMessages.Add($_)
		Write-BuildText Yellow (*II ${-t})
		throw
	}
	finally {
		$null = $BuildInfo.Tasks.Add(${-t}), $BuildInfo.AllTasks.Add(${-t})
		. *Do Exit-BuildTask ${-t}
	}
}

function *TryTask($Try, $Task) {
	$t = $BuildList[$Try]
	if (!$t.If) {return}

	if ($t.Jobs -contains $Task) {
		if ($t.Try -notcontains $Task) {
			"Task '$Try' calls failed '$Task' not protected."
		}
		return
	}

	foreach($_ in $t.Jobs) { if ($_ -is [string]) {
		$w = *TryTask $_ $Task
		if ($w) {return $w}
	}}
}

function *TestTask($Task) {
	foreach($_ in $Task) {
		$t = $BuildList[$_]
		if (!$t) {throw "Task '$_' is not defined."}
		*TestTree $t ([System.Collections.ArrayList]@())
	}
}

function *TestTree($Task, $Done) {
	$n = 1 + $Done.Add($Task)
	foreach($_ in $Task.Jobs) { if ($_ -is [string]) {
		$t = $BuildList[$_]
		if (!$t) {throw *Fix "Task '$($Task.Name)': Task '$_' is not defined." $Task}
		if ($Done.Contains($t)) {throw *Fix "Task '$($Task.Name)': Cyclic reference to '$_'." $Task}
		*TestTree $t $Done
		$Done.RemoveRange($n, $Done.Count - $n)
	}}
}

function *Summary($Done, $Tasks, $Errors, $Warnings, $Span) {
	$c, $m = if ($Done -eq 2) {'Red', 'Build FAILED'}
	elseif ($Errors) {'Red', 'Build completed with errors'}
	elseif ($Warnings) {'Yellow', 'Build succeeded with warnings'}
	else {'Green', 'Build succeeded'}
	Write-BuildText $c "$m. $Tasks tasks, $Errors errors, $Warnings warnings, $Span"
}

function *Do {
	if (!$WhatIf) {
		Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
		. $args[0] $args[1] $args[2]
	}
}

function Enter-BuildScript {}
function Exit-BuildScript {}
function Enter-BuildTask {}
function Exit-BuildTask {}
function Enter-BuildJob {}
function Exit-BuildJob {}
function Export-Build {}
function Import-Build {}

$ErrorActionPreference = 'Stop'
${private:-resume} = $null
${private:-location} = $PSCmdlet.GetUnresolvedProviderPathFromPSPath('')

try {
	if ($Checkpoint) {
		$Checkpoint = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Checkpoint)
	}
	if ($Checkpoint -and !($Task -or $File -or $Parameters)) {
		$_ = Import-Clixml $Checkpoint
		$Task, $BuildFile, $Parameters, ${-resume}, ${private:-data} = $_
	}
	elseif ($File) {
		$BuildFile = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($File)
		if (!([System.IO.File]::Exists($BuildFile))) {throw "Build file does not exist: '$BuildFile'."}
	}
	else {
		$BuildFile = Get-BuildFile ${-location}
		if (!$BuildFile) {
			$BuildFile = *Hook $Hook GetFile
			if (!$BuildFile) {throw "Default build file is not found."}
		}
	}
	$BuildRoot = Split-Path $BuildFile
}
catch {*Die "$_" ObjectNotFound}

${private:-up} = $PSCmdlet.SessionState.PSVariable.Get('BuildInfo')
if (${-up}) {
	${-up} = if (${-up}.Description -eq 'Invoke-Build') {${-up}.Value}
}

Set-Alias assert Assert-BuildTrue
Set-Alias error Get-BuildError
Set-Alias exec Invoke-BuildExec
Set-Alias property Get-BuildProperty
Set-Alias task Add-BuildTask
Set-Alias use Use-BuildAlias
Set-Alias Invoke-Build $MyInvocation.MyCommand.Path
Set-Alias Invoke-Builds (Join-Path (Split-Path $MyInvocation.MyCommand.Path) 'Invoke-Builds.ps1')
New-Variable -Name BuildList -Option Constant -Value ([System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase))
New-Variable -Name BuildInfo -Option Constant -Description Invoke-Build -Value (
	Select-Object -InputObject 1 -Property AllTasks, AllMessages, AllErrorCount, AllWarningCount, Tasks, Messages, ErrorCount, WarningCount,
	Started, Elapsed, Error, Parameters, Checkpoint
)
$BuildInfo.AllTasks = [System.Collections.ArrayList]@()
$BuildInfo.AllMessages = [System.Collections.ArrayList]@()
$BuildInfo.AllErrorCount = 0
$BuildInfo.AllWarningCount = 0
$BuildInfo.Tasks = [System.Collections.ArrayList]@()
$BuildInfo.Messages = [System.Collections.ArrayList]@()
$BuildInfo.ErrorCount = 0
$BuildInfo.WarningCount = 0
$BuildInfo.Started = [System.DateTime]::Now
$BuildInfo.Parameters = $Parameters
$BuildInfo.Checkpoint = $Checkpoint
if ('?' -eq $Task) {$WhatIf = $true}
if ($Result) {
	$_ = if ('?' -eq $Task) {$BuildList} else {$BuildInfo}
	if ($Result -is [string]) {New-Variable -Force -Scope 1 $Result $_}
	else {$Result.Value = $_}
}
$BuildTask = $Task
${private:-Result} = $Result
${private:-Safe} = $Safe
Remove-Variable Task, File, Parameters, Hook, Checkpoint, Result, Safe

${private:-done} = 0
try {
	Set-Location -LiteralPath $BuildRoot -ErrorAction Stop
	Write-BuildText DarkYellow "Build $($BuildTask -join ', ') $BuildFile"
	$_ = $BuildInfo.Parameters
	$_ = if ($_) {. $BuildFile @_} else {. $BuildFile}
	if (!$BuildList.Count) {throw "There is no task in '$BuildFile'."}
	$_
	foreach($_ in $_) { if ($_ -is [scriptblock]) {throw "Invalid build script syntax at the script block {$_}"} }

	foreach(${private:-t} in $BuildList.Values) {
		try {
			if (${-t}.Before) {*Alter ${-t}.Name ${-t}.Before}
			if (${-t}.After) {*Alter ${-t}.Name ${-t}.After -After}
		}
		catch {throw *Fix "Task '$(${-t}.Name)': $_" ${-t}}
	}

	if ('?' -eq $BuildTask) {
		*TestTask $BuildList.Keys
		if (!${-Result}) {
			foreach($_ in $BuildList.Values) {@"
$($_.Name) $(($_.Jobs | %{ if ($_ -is [string]) {$_} else {'{..}'} }) -join ', ') $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)
"@}
		}
		return
	}

	if ('*' -eq $BuildTask) {
		*TestTask $BuildList.Keys
		$BuildTask = foreach($_ in $BuildList.Keys) {
			foreach(${private:-t} in $BuildList.Values) {
				if (${-t}.Jobs -contains $_) {
					$_ = $null
					break
				}
			}
			if ($_) {$_}
		}
	}
	else {
		if (!$BuildTask -or '.' -eq $BuildTask) {
			$BuildTask = if ($BuildList.Contains('.')) {'.'} else {$BuildList.Item(0).Name}
		}
		*TestTask $BuildTask
	}

	try {
		. *Do Enter-BuildScript
		if (${-resume}) {
			. *Do Import-Build ${-data}
			foreach($_ in ${-resume}.GetEnumerator()) {
				$BuildList[$_.Key].Elapsed = $_.Value
			}
		}
		foreach($_ in $BuildTask) {
			*Task $_
		}
		if ($BuildInfo.Checkpoint) {
			[System.IO.File]::Delete($BuildInfo.Checkpoint)
		}
	}
	finally {
		. *Do Exit-BuildScript
	}
	${-done} = 1
}
catch {
	${-done} = 2
	$BuildInfo.Error = $_
	if (!${-Safe}) {if (*My) {$PSCmdlet.ThrowTerminatingError($_)} else {throw}}
}
finally {
	Set-Location -LiteralPath ${-location} -ErrorAction Stop
	if (${-done}) {
		$BuildInfo.Elapsed = [System.DateTime]::Now - $BuildInfo.Started
		$BuildInfo.Messages
		*Summary ${-done} $BuildInfo.Tasks.Count $BuildInfo.ErrorCount $BuildInfo.WarningCount $BuildInfo.Elapsed

		if (${-up}) {
			${-up}.AllTasks.AddRange($BuildInfo.AllTasks)
			${-up}.AllMessages.AddRange($BuildInfo.AllMessages)
			${-up}.AllErrorCount += $BuildInfo.AllErrorCount
			${-up}.AllWarningCount += $BuildInfo.AllWarningCount
		}
		elseif ($BuildInfo.AllTasks.Count -ne $BuildInfo.Tasks.Count) {
			$BuildInfo.AllMessages
			*Summary ${-done} $BuildInfo.AllTasks.Count $BuildInfo.AllErrorCount $BuildInfo.AllWarningCount $BuildInfo.Elapsed
		}
	}
}
