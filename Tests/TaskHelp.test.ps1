
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

	$r = Show-TaskHelp . z.ps1 -Format {$args[0]}

	equals $log.Value "Task 'Test': unknown parameter 'Missing.'."
	equals $r.Task Test
	equals $r.Jobs.Count 1
	equals $r.Jobs[0] '{}'
	equals $r.Synopsis Test-synopsis
	assert ($r.Location -match 'z\.ps1:\d+$')
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

	# call with the default format
	Show-TaskHelp . z.ps1

	Remove-Item z.ps1
}

# Use this repo build script, test code and tree processing.
task UndocumentedStuff {
	# call with the default format
	Show-TaskHelp '' ../.build.ps1

	# default call with code and trees
	$r = Show-TaskHelp '' ../.build.ps1 -Format {$args[0]}
	equals $r.Task .
	equals ($r.Jobs -join '|') 'Help|Test|Clean'
	equals $r.Synopsis 'The default task: make, test, clean.'
	assert ($r.Location -match '\.build\.ps1:\d+$')
	if ($V3) {
		equals $r.Parameters.Count 1
		equals $r.Parameters[0].Name NoTestDiff
		equals $r.Parameters[0].Type SwitchParameter
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
	$r = Show-TaskHelp '' ../.build.ps1 -Format {$args[0]} -NoCode -NoTree
	equals $r.Parameters.Count 0
	equals $r.Environment.Count 0
}
