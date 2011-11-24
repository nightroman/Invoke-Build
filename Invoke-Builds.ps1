
<#
Invoke-Build - Build Automation in PowerShell
Copyright (c) 2011 Roman Kuzmin

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
$ErrorActionPreference = 'Stop'

if ($Host.Name -eq 'Default Host' -or !$Host.UI -or !$Host.UI.RawUI) {
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

function Fix($_) {"$_`r`n$($_.InvocationInfo.PositionMessage.Trim().Replace("`n", "`r`n"))"}

### main

# this info
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

# runspace pool
if ($MaximumBuilds -lt 1) {throw "MaximumBuilds should be a positive number."}
$pool = [RunspaceFactory]::CreateRunspacePool(1, [Math]::Min($Build.Count, $MaximumBuilds))
$failures = @()

try {
	### get the engine
	$root = Split-Path $MyInvocation.MyCommand.Path
	$path = Join-Path $root 'Invoke-Build.ps1'
	if (![System.IO.File]::Exists($path)) {"Required script '$path' does not exist."}

	### build parameters
	for ($$ = 0; $$ -lt $Build.Count; ++$$) {
		$b = @{} + $Build[$$]

		$file = $b['File']
		if (!$file) {throw "'Build' misses the mandatory key 'File'."}
		$file = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($file)
		if (![System.IO.File]::Exists($file)) {"Build script '$file' does not exist."}

		$b.Result = [ref]$null
		$b.File = $file
		$b.Safe = $true
		$Build[$$] = $b
	}

	### begin async
	$pool.Open()
	$works = @()
	for ($$ = 0; $$ -lt $Build.Count; ++$$) {
		$work = @{}
		$works += $work

		$b = $Build[$$]
		$work.Title = "($($$ + 1)/$($Build.Count)) $($b.File)"

		$log = $b['Log']
		if ($log) {
			$work.Temp = $false
			$b.Remove('Log')
			$log = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($log)
			[System.IO.File]::Delete($log)
		}
		else {
			$work.Temp = $true
			$log = [System.IO.Path]::GetTempFileName()
		}
		$work.Log = $log

		$p = [PowerShell]::Create()
		$p.RunspacePool = $pool
		$work.Posh = $p
		$null = $p.AddCommand($path).AddParameters($b).AddCommand('Out-File').AddParameter('FilePath', $log).AddParameter('Encoding', 'UTF8')

		# start job
		$work.Job = $p.BeginInvoke()
	}

	### wait
	$stopwatch = [Diagnostics.Stopwatch]::StartNew()
	$done = @(foreach($_ in $works) {
		$left = $Timeout - $stopwatch.ElapsedMilliseconds
		if ($left -gt 0) {$_.Job.AsyncWaitHandle.WaitOne($left)} else {$false}
	})

	### end async
	for ($$ = 0; $$ -lt $Build.Count; ++$$) {
		$work = $works[$$]
		Write-BuildText Cyan "Build $($work.Title):"

		$p = $work.Posh
		$exception = $null
		try {
			if ($done[$$]) {
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
		if ($work.Temp) {
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

		# result and error
		$r = $Build[$$].Result.Value
		$_ = if ($r) {
			$r.Error
			$info.Tasks.AddRange($r.AllTasks)
			$info.Messages.AddRange($r.AllMessages)
			$info.ErrorCount += $r.AllErrorCount
			$info.WarningCount += $r.AllWarningCount
		}
		else {
			"'$($Build[$$].File)' invocation failed: $exception"
		}
		if (!$_) {$_ = $exception}
		if ($_) {
			Write-BuildText Cyan "Build $($work.Title) FAILED."
			$_ = if ($_ -is [System.Management.Automation.ErrorRecord]) {Fix $_} else {"$_"}
			Write-BuildText Red "ERROR: $_"
			$failures += @{File=$Build[$$].File; Error=$_}
		}
		else {
			Write-BuildText Cyan "Build $($work.Title) succeeded."
		}
	}

	# fail
	if ($failures) {
		Write-Error -ErrorAction Stop (.{
			"Parallel build failures:"
			foreach($_ in $failures) {
				"Build: $($_.File)"
				"ERROR: $($_.Error)"
			}
		} | Out-String)
	}
}
catch {
	if ($_.InvocationInfo.ScriptName -ne $MyInvocation.MyCommand.Path) {throw}
	$PSCmdlet.ThrowTerminatingError($_)
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
