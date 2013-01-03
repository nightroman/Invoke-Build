
<#
Invoke-Build - PowerShell Task Scripting
Copyright (c) 2011-2013 Roman Kuzmin

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

#.ExternalHelp Invoke-Build-Help.xml
param
(
	[Parameter(Position=0)][hashtable[]]$Build,
	$Result,
	[int]$Timeout = [int]::MaxValue,
	[int]$MaximumBuilds = [Environment]::ProcessorCount
)

if (!$Host.UI -or !$Host.UI.RawUI -or 'Default Host', 'ServerRemoteHost' -contains $Host.Name) {
	function Write-Build($Color, [string]$Text)
	{$Text}
}
else {
	function Write-Build([ConsoleColor]$Color, [string]$Text)
	{$i = $Host.UI.RawUI; $_ = $i.ForegroundColor; try {$i.ForegroundColor = $Color; $Text} finally {$i.ForegroundColor = $_}}
}

function *EI($_)
{"$_`r`n$($_.InvocationInfo.PositionMessage.Trim())"}

function *TE($M, $C=0)
{$PSCmdlet.ThrowTerminatingError((New-Object System.Management.Automation.ErrorRecord ([Exception]"$M"), $null, $C, $null))}

### main

# info, result
$info = [PSCustomObject]@{
	Tasks = [System.Collections.ArrayList]@()
	Errors = [System.Collections.ArrayList]@()
	Warnings = [System.Collections.ArrayList]@()
	Started = [DateTime]::Now
	Elapsed = $null
}
if ($Result) {if ($Result -is [string]) {New-Variable -Force -Scope 1 $Result $info} else {$Result.Value = $info}}

# no builds
if (!$Build) {return}

### engine
$engine = Join-Path (Split-Path $MyInvocation.MyCommand.Path) Invoke-Build.ps1
if (![System.IO.File]::Exists($engine)) {*TE "Missing script '$engine'." 13}

### works
$works = @()
for ($1 = 0; $1 -lt $Build.Count; ++$1) {
	$b = @{} + $Build[$1]

	$file = $b['File']
	if (!$file) {*TE "Build parameter File is missing or empty." 5}
	$file = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($file)
	if (![System.IO.File]::Exists($file)) {*TE "Missing script '$file'." 13}

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
if ($MaximumBuilds -lt 1) {*TE "MaximumBuilds should be a positive number." 5}
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
		Write-Build Cyan $work.Title
		$t = $Timeout - $stopwatch.ElapsedMilliseconds
		$work.Done = if ($t -gt 0) {$work.Job.AsyncWaitHandle.WaitOne($t)}
	}

	### end async
	foreach($work in $works) {
		Write-Build Cyan "Build $($work.Title):"

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
			$info.Tasks.AddRange($r.Tasks)
			$info.Errors.AddRange($r.Errors)
			$info.Warnings.AddRange($r.Warnings)
		}
		else {
			"'$($work.Build.File)' invocation failed: $exception"
		}
		if (!$_) {$_ = $exception}
		if ($_) {
			Write-Build Cyan "Build $($work.Title) FAILED."
			$_ = if ($_ -is [System.Management.Automation.ErrorRecord]) {*EI $_} else {"$_"}
			Write-Build Red "ERROR: $_"
			$failures += @{File=$work.Title; Error=$_}
		}
		else {
			Write-Build Cyan "Build $($work.Title) succeeded."
		}
	}

	# fail
	if ($failures) {
		*TE ($(
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
	$errors = $info.Errors.Count
	$warnings = $info.Warnings.Count
	$info.Elapsed = [DateTime]::Now - $info.Started

	$up = $PSCmdlet.SessionState.PSVariable.Get('*')
	if ($up -and ($up = if ($up.Description -eq 'Invoke-Build') {$up.Value})) {
		$up.Tasks.AddRange($info.Tasks); $up.Errors.AddRange($info.Errors); $up.Warnings.AddRange($info.Warnings)
	}

	$color, $text = if ($failures) {'Red', 'Builds FAILED'}
	elseif ($errors) {'Red', 'Builds completed with errors'}
	elseif ($warnings) {'Yellow', 'Builds succeeded with warnings'}
	else {'Green', 'Builds succeeded'}

	Write-Build $color @"
Tasks: $($info.Tasks.Count) tasks, $errors errors, $warnings warnings
$text. $($Build.Count) builds, $($failures.Count) failed, $($info.Elapsed)
"@
}
