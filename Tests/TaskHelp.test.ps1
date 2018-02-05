
<#
.Synopsis
	Tests Show-TaskHelp.ps1

.Example
	Invoke-Build * TaskHelp.test.ps1
#>

$V3 = $PSVersionTable.PSVersion.Major -ge 3

# This script was the first on testing and it caught a few issues.
task DocumentedStuff {
	Set-Content z.ps1 @'
<#
.Parameter Platform
	Build platform.
.Parameter Configuration
	Build configuration.
#>

[CmdletBinding()]
param(
	$Platform,
	$Configuration,
	$NotDocumented,
	$NotUsed
)

# Synopsis: Test-synopsis
# Parameters: Platform, Configuration, NotDocumented, Missing.
# Environment: Bar2, Bar1
task Test {
	$Verbose # must not be shown as parameter
}
'@

	$log = @{Value = ''}
	Set-Alias Write-Warning log
	function log($m) {$log.Value += $m}

	# call with the default format
	Show-TaskHelp . z.ps1
	equals $log.Value "Task 'Test': unknown parameter 'Missing.'."

	$r = Show-TaskHelp . z.ps1 -Format {$args[0]}

	equals $r.Task.Count 1
	equals $r.Task[0].Name Test
	equals $r.Task[0].Synopsis Test-synopsis
	equals $r.Jobs.Count 1
	equals $r.Jobs[0].Name 'Test'
	assert ($r.Jobs[0].Location -match 'z\.ps1:\d+$')
	equals $r.Parameters.Count 3
	equals $r.Parameters[0].Name Configuration
	equals $r.Parameters[0].Type Object
	equals $r.Parameters[0].Description 'Build configuration.'
	equals $r.Parameters[1].Name NotDocumented
	equals $r.Parameters[1].Type Object
	equals $r.Parameters[1].Description $null
	equals $r.Parameters[2].Name Platform
	equals $r.Parameters[2].Type Object
	equals $r.Parameters[2].Description 'Build platform.'
	equals $r.Environment.Count 2
	equals $r.Environment[0] Bar1
	equals $r.Environment[1] Bar2

	Remove-Item z.ps1
}

# Use this repo build script, test code and tree processing.
task UndocumentedStuff {
	# call with the default format
	Show-TaskHelp '' ../.build.ps1

	# default call with code and trees
	$r = Show-TaskHelp '' ../.build.ps1 -Format {$args[0]}
	equals $r.Task.Count 1
	equals $r.Task[0].Name .
	equals $r.Task[0].Synopsis 'The default task: make, test, clean.'
	equals (($r.Jobs | Select-Object -ExpandProperty Name) -join ', ') 'Help, Test3, Test2, Test6, Clean'
	foreach($job in $r.Jobs) {
		assert ($job.Location -match '\.build\.ps1:\d+$')
	}
	if ($V3) {
		equals $r.Parameters.Count 1
		equals $r.Parameters[0].Name NoTestDiff
		equals $r.Parameters[0].Type switch
		equals $r.Parameters[0].Description $null
		equals $r.Environment.Count 2
		equals $r.Environment[0] MERGE
		equals $r.Environment[1] powershell6
	}
	else {
		equals $r.Parameters.Count 0
		equals $r.Environment.Count 0
	}

	# call with no code and trees
	$r = Show-TaskHelp '' ../.build.ps1 -Format {$args[0]} -NoCode
	equals $r.Parameters.Count 0
	equals $r.Environment.Count 0
}

# Skip variables on the left hand of assignments.
# Cover missing help `Parameters` in strict mode.
task SkipAssignment {
	Set-Content z.ps1 @'
param(
	$Param1
)
task Test {
	$Param1 = 1
	$env:Param2 = 2
}
'@

	$r = Show-TaskHelp . z.ps1 -Format {$args[0]}
	equals $r.Parameters.Count 0
	equals $r.Environment.Count 0

	Remove-Item z.ps1
}

# Test two tasks and cover missed own task jobs.
task TwoTasks {
	Set-Content z.ps1 @'
task Build {}
task Version {}
task Release Version, {}
'@

	$r = Show-TaskHelp build, release z.ps1 -Format {$args[0]}
	equals $r.Task.Count 2
	equals $r.Task[0].Name Build
	equals $r.Task[1].Name Release
	equals $r.Jobs.Count 3
	equals $r.Jobs[0].Name Build
	equals $r.Jobs[1].Name Version
	equals $r.Jobs[2].Name Release

	Remove-Item z.ps1
}
