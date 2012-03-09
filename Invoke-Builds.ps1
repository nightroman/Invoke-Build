
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
	[Parameter(Position=0)][hashtable[]]$Build,
	$Result,
	[int]$Timeout = [int]::MaxValue,
	[int]$MaximumBuilds = [System.Environment]::ProcessorCount
)
Set-StrictMode -Version 2

if ($Host.Name -eq 'Default Host' -or $Host.Name -eq 'ServerRemoteHost' -or !$Host.UI -or !$Host.UI.RawUI) {
	function Write-BuildText([System.ConsoleColor]$Color, [string]$Text) {$Text}
}
else {
	function Write-BuildText([System.ConsoleColor]$Color, [string]$Text)
	{
		$saved = $Host.UI.RawUI.ForegroundColor
		try {
			$Host.UI.RawUI.ForegroundColor = $Color
			$Text
		}
		finally {
			$Host.UI.RawUI.ForegroundColor = $saved
		}
	}
}

function Fix($_)
{"$_`r`n$($1 = $_.InvocationInfo.PositionMessage; if ($1.StartsWith("`n")) {$1.Trim().Replace("`n", "`r`n")} else {$1})"}

function Die([string]$Message, [System.Management.Automation.ErrorCategory]$Category = 0)
{$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([System.Exception]$Message), $null, $Category, $null))}

### main

# info, result
$info = (Select-Object Tasks, Messages, ErrorCount, WarningCount, Started, Elapsed -InputObject 1)
$info.Tasks = [System.Collections.ArrayList]@()
$info.Messages = [System.Collections.ArrayList]@()
$info.ErrorCount = 0
$info.WarningCount = 0
$info.Started = [System.DateTime]::Now
if ($Result) {
	if ($Result -is [string]) {New-Variable -Force -Scope 1 $Result $info}
	else {$Result.Value = $info}
}

# no builds
if (!$Build) {return}

### engine
$engine = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path), 'Invoke-Build.ps1')
if (![System.IO.File]::Exists($engine)) {Die "Required script '$engine' does not exist." ObjectNotFound}

### works
$works = @()
for ($1 = 0; $1 -lt $Build.Count; ++$1) {
	$b = @{} + $Build[$1]

	$file = $b['File']
	if (!$file) {Die "Build parameter File is missing or empty." InvalidArgument}
	$file = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($file)
	if (![System.IO.File]::Exists($file)) {Die "Build file '$file' does not exist." ObjectNotFound}

	$b.Result = @{}
	$b.File = $file
	$b.Safe = $true
	$Build[$1] = $b

	$work = @{}
	$works += $work
	$work.Build = $b
	$work.Title = "($($1 + 1)/$($Build.Count)) $file"
}

# runspace pool
if ($MaximumBuilds -lt 1) {Die "MaximumBuilds should be a positive number." InvalidArgument}
$pool = [RunspaceFactory]::CreateRunspacePool(1, $MaximumBuilds)
$failures = @()

try {
	### begin async
	$pool.Open()
	foreach($work in $works) {
		$b = $work.Build

		# log
		$log = $b['Log']
		if ($log) {
			$b.Remove('Log')
			$log = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($log)
			[System.IO.File]::Delete($log)
		}
		else {
			$work.Temp = $true
			$log = [System.IO.Path]::GetTempFileName()
		}
		$work.Log = $log

		# posh
		$p = [PowerShell]::Create()
		$p.RunspacePool = $pool
		$work.Posh = $p
		$null = $p.AddCommand($engine).AddParameters($b).AddCommand('Out-File').AddParameter('FilePath', $log).AddParameter('Encoding', 'UTF8')

		# start
		$work.Job = $p.BeginInvoke()
	}

	### wait
	$stopwatch = [Diagnostics.Stopwatch]::StartNew()
	foreach($work in $works) {
		Write-BuildText Cyan $work.Title
		$t = $Timeout - $stopwatch.ElapsedMilliseconds
		$work.Done = if ($t -gt 0) {$work.Job.AsyncWaitHandle.WaitOne($t)}
	}

	### end async
	foreach($work in $works) {
		Write-BuildText Cyan "Build $($work.Title):"

		$p = $work.Posh
		$exception = $null
		try {
			if ($work.Done) {
				$p.EndInvoke($work.Job)
			}
			else {
				$p.Stop()
				$exception = "Build timed out."
			}
		}
		catch {
			$exception = $_
		}

		# log
		$log = $work.Log
		if ($work['Temp']) {
			try {
				$read = [System.IO.File]::OpenText($log)
				for(;;) { $_ = $read.ReadLine(); if ($null -eq $_) {break}; $_ }
				$read.Close()
			}
			catch {}
			[System.IO.File]::Delete($log)
		}
		else {
			"Log: $log"
		}

		# result, error
		$r = $work.Build.Result['Value']
		$_ = if ($r) {
			$r.Error
			$info.Tasks.AddRange($r.AllTasks)
			$info.Messages.AddRange($r.AllMessages)
			$info.ErrorCount += $r.AllErrorCount
			$info.WarningCount += $r.AllWarningCount
		}
		else {
			"'$($work.Build.File)' invocation failed: $exception"
		}
		if (!$_) {$_ = $exception}
		if ($_) {
			Write-BuildText Cyan "Build $($work.Title) FAILED."
			$_ = if ($_ -is [System.Management.Automation.ErrorRecord]) {Fix $_} else {"$_"}
			Write-BuildText Red "ERROR: $_"
			$failures += @{File=$work.Title; Error=$_}
		}
		else {
			Write-BuildText Cyan "Build $($work.Title) succeeded."
		}
	}

	# fail
	if ($failures) {
		Die ($(
			"Failed builds:"
			foreach($_ in $failures) {
				"Build: $($_.File)"
				"ERROR: $($_.Error)"
			}
		) -join "`r`n")
	}
}
finally {
	$pool.Close()
	$errors = $info.ErrorCount
	$warnings = $info.WarningCount
	$info.Elapsed = [System.DateTime]::Now - $info.Started

	$up = $PSCmdlet.SessionState.PSVariable.Get('BuildInfo')
	if ($up) {$up = if ($up.Description -eq 'Invoke-Build') {$up.Value}}
	if ($up) {
		$up.AllTasks.AddRange($info.Tasks)
		$up.AllMessages.AddRange($info.Messages)
		$up.AllErrorCount += $errors
		$up.AllWarningCount += $warnings
	}

	$color, $text = if ($failures) {'Red', 'Builds FAILED'}
	elseif ($errors) {'Red', 'Builds completed with errors'}
	elseif ($warnings) {'Yellow', 'Builds succeeded with warnings'}
	else {'Green', 'Builds succeeded'}

	Write-BuildText $color @"
Tasks: $($info.Tasks.Count) tasks, $errors errors, $warnings warnings
$text. $($Build.Count) builds, $($failures.Count) failed, $($info.Elapsed)
"@
}
