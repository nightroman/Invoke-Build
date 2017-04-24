
<#
Copyright 2011-2017 Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
#>

#.ExternalHelp Invoke-Build-Help.xml
param(
	[Parameter(Position=0)][hashtable[]]$Build,
	$Result,
	[int]$Timeout=[int]::MaxValue,
	[int]$MaximumBuilds=[Environment]::ProcessorCount
)

# info, result
$info = [PSCustomObject]@{
	Tasks = [System.Collections.Generic.List[object]]@()
	Errors = [System.Collections.Generic.List[object]]@()
	Warnings = [System.Collections.Generic.List[object]]@()
	Started = [DateTime]::Now
	Elapsed = $null
}
if ($Result) {
	if ($Result -is [string]) {
		New-Variable $Result $info -Scope 1 -Force
	}
	else {
		$Result.Value = $info
	}
}

# no builds
if (!$Build) {return}

# engine
$ib = Join-Path (Split-Path $MyInvocation.MyCommand.Path) Invoke-Build.ps1
try {. $ib .} catch {$PSCmdlet.ThrowTerminatingError($_)}

### works
$works = @()
for ($1 = 0; $1 -lt $Build.Count) {
	$b = @{} + $Build[$1]
	$Build[$1++] = $b

	if ($file = $b['File']) {
		if (![System.IO.File]::Exists(($file = *Path $file))) {*Die "Missing script '$file'." 13}
	}
	elseif (!($file = Get-BuildFile (*Path))) {
		*Die "Missing default script in build $1." 5
	}

	$b.Result = @{}
	$b.File = $file
	$b.Safe = $true

	$work = @{}
	$works += $work
	$work.Build = $b
	$work.Title = "($1/$($Build.Count)) $file"
}

# runspace pool
if ($MaximumBuilds -lt 1) {*Die "MaximumBuilds should be a positive number." 5}
$pool = [RunspaceFactory]::CreateRunspacePool(1, $MaximumBuilds)
$failures = @()

try {
	### begin
	$pool.Open()
	foreach($work in $works) {
		$b = $work.Build

		# log
		if ($log = $b['Log']) {
			$b.Remove('Log')
			[System.IO.File]::Delete(($log = *Path $log))
		}
		else {
			$work.Temp = $true
			$log = [System.IO.Path]::GetTempFileName()
		}
		$work.Log = $log

		# PS
		$work.PS = $ps = [PowerShell]::Create()
		$ps.RunspacePool = $pool
		$work.Job =
		$ps.AddCommand($ib).AddParameters($b).AddCommand('Out-File').AddParameter('FilePath', $log).AddParameter('Encoding', 'UTF8').BeginInvoke()
	}

	### wait
	$stopwatch = [Diagnostics.Stopwatch]::StartNew()
	foreach($work in $works) {
		Write-Build Cyan $work.Title
		$t = $Timeout - $stopwatch.ElapsedMilliseconds
		$work.Done = if ($t -gt 0) {$work.Job.AsyncWaitHandle.WaitOne($t)}
	}

	### end
	foreach($work in $works) {
		Write-Build Cyan "Build $($work.Title):"

		$ps = $work.PS
		$exception = $null
		try {
			if ($work.Done) {
				$ps.EndInvoke($work.Job)
			}
			else {
				$ps.Stop()
				$exception = 'Build timed out.'
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
				while($null -ne ($_ = $read.ReadLine())) {$_}
				$read.Close()
			}
			catch {
				Write-Warning $_
			}
			[System.IO.File]::Delete($log)
		}
		else {
			"Log: $log"
		}

		# result, error
		$_ = if ($r = $work.Build.Result['Value']) {
			$r.Error
			$info.Tasks.AddRange($r.Tasks)
			$info.Errors.AddRange($r.Errors)
			$info.Warnings.AddRange($r.Warnings)
		}
		else {
			"'$($work.Build.File)' invocation failed: $exception"
		}
		if (!$_) {
			$_ = $exception
		}
		if ($_) {
			Write-Build Cyan "Build $($work.Title) FAILED."
			$_ = if ($_ -is [System.Management.Automation.ErrorRecord]) {*Error $_ $_} else {"$_"}
			Write-Build Red "ERROR: $_"
			$failures += @{
				File = $work.Title
				Error = $_
			}
		}
		else {
			Write-Build Cyan "Build $($work.Title) succeeded."
		}
	}

	# fail
	if ($failures) {
		*Die ($(
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

	if (($up = $PSCmdlet.SessionState.PSVariable.Get('*')) -and ($up = if ($up.Description -eq 'IB') {$up.Value})) {
		$up.Tasks.AddRange($info.Tasks)
		$up.Errors.AddRange($info.Errors)
		$up.Warnings.AddRange($info.Warnings)
	}

	$color, $text = if ($failures) {12, 'Builds FAILED'}
	elseif ($errors) {14, 'Builds completed with errors'}
	elseif ($warnings) {14, 'Builds succeeded with warnings'}
	else {10, 'Builds succeeded'}

	Write-Build $color @"
Tasks: $($info.Tasks.Count) tasks, $errors errors, $warnings warnings
$text. $($Build.Count) builds, $($failures.Count) failed $($info.Elapsed)
"@
}
