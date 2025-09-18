<#
.Synopsis
	Tests Show-TaskHelp.ps1 (Invoke-Build -WhatIf)
#>

Import-Module .\Tools

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

	# call by WhatIf
	Invoke-Build -File z.ps1 -WhatIf
	equals $log.Value "Task 'Test': unknown parameter 'Missing.'."

	$r = Show-TaskHelp.ps1 . z.ps1 -Format {$args[0]}

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
# 2024-02-29 v2 started to fail, skip.
task UndocumentedStuff {
	# call by WhatIf
	Invoke-Build -File ../1.build.ps1 -WhatIf

	# test default task call with code
	$r = Show-TaskHelp.ps1 '' ../1.build.ps1 -Format {$args[0]}
	equals $r.Task.Count 1
	equals $r.Task[0].Name .
	equals $r.Task[0].Synopsis 'The default task: make, test, clean.'
	equals (($r.Jobs | Select-Object -ExpandProperty Name) -join ', ') 'help, desktop, core, clean'
	foreach($job in $r.Jobs) {
		assert ($job.Location -match '\.build\.ps1:\d+$')
	}

	#! fixed .Parameters = 1 object, not array
	equals $r.Parameters.Count 1
	equals $r.Parameters[0].Name NoTestDiff
	equals $r.Parameters[0].Type switch
	equals $r.Parameters[0].Description $null
	equals $r.Environment.Count 0

	# test a task with code and environment variable
	$r = Show-TaskHelp.ps1 test ../1.build.ps1 -Format {$args[0]}
	equals $r.Task.Count 1
	equals $r.Task[0].Name test
	equals $r.Task[0].Synopsis 'Test and check expected output.'
	equals (($r.Jobs | Select-Object -ExpandProperty Name) -join ', ') 'test'
	foreach($job in $r.Jobs) {
		assert ($job.Location -match '\.build\.ps1:\d+$')
	}

	#! fixed .Parameters = 1 object, not array
	equals $r.Parameters.Count 1
	equals $r.Parameters[0].Name NoTestDiff
	equals $r.Parameters[0].Type switch
	equals $r.Parameters[0].Description $null
	equals $r.Environment.Count 1
	equals $r.Environment[0] MERGE

	# call with -NoCode
	$r = Show-TaskHelp.ps1 test ../1.build.ps1 -Format {$args[0]} -NoCode
	equals $r.Parameters.Count 0
	equals $r.Environment.Count 0
}

# Skip variables on the left hand of assignments.
# Cover missing help `Parameters` in strict mode.
task SkipAssignment {
	Set-Content z.ps1 {
		param($Param1)
		task Test {
			$Param1 = 1
			$env:Param2 = 2
		}
	}

	# call by WhatIf
	Invoke-Build . z.ps1 -WhatIf

	# call and test
	$r = Show-TaskHelp.ps1 . z.ps1 -Format {$args[0]}
	equals $r.Parameters.Count 0
	equals $r.Environment.Count 0

	Remove-Item z.ps1
}

# Test two tasks and cover missed own task jobs.
task TwoTasks {
	Set-Content z.ps1 {
		task Build {}
		task Version {}
		task Release Version, {}
	}

	# call by WhatIf
	Invoke-Build build, release z.ps1 -WhatIf

	# call and test
	$r = Show-TaskHelp.ps1 build, release z.ps1 -Format {$args[0]}
	equals $r.Task.Count 2
	equals $r.Task[0].Name Build
	equals $r.Task[1].Name Release
	equals $r.Jobs.Count 3
	equals $r.Jobs[0].Name Build
	equals $r.Jobs[1].Name Version
	equals $r.Jobs[2].Name Release

	Remove-Item z.ps1
}

# Tasks with `If` script must be shown in Jobs, even without actions.
task ForkWithIf {
	Set-Content z.ps1 {
		task t1 -if {} t2
		task t2 {}
	}

	# call by WhatIf
	Invoke-Build t1 z.ps1 -WhatIf

	# call and test
	$r = Show-TaskHelp.ps1 t1 z.ps1 -Format {$args[0]}
	equals $r.Task.Count 1
	equals $r.Task[0].Name t1
	equals $r.Jobs.Count 2
	equals $r.Jobs[0].Name t2
	equals $r.Jobs[1].Name t1

	Remove-Item z.ps1
}

# Cover -If, -Inputs, -Outputs in addition to -Jobs.
task IfInputsOutputs {
	Set-Content z.ps1 {
		param($If, $Inputs, $Outputs)
		task t1 -If {$If} -Inputs {$Inputs} -Outputs {$Outputs} {}
	}

	# call by WhatIf
	Invoke-Build t1 z.ps1 -WhatIf

	# call and test
	$r = Show-TaskHelp.ps1 t1 z.ps1 -Format {$args[0]}
	equals $r.Parameters.Count 3
	equals $r.Parameters[0].Name If
	equals $r.Parameters[1].Name Inputs
	equals $r.Parameters[2].Name Outputs

	Remove-Item z.ps1
}
