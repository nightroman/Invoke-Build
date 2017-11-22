
<#
.Synopsis
	Assorted tests, fixed issues..

.Example
	Invoke-Build * Fixed.test.ps1
#>

Set-StrictMode -Version Latest

. ./Shared.ps1

# Synopsis: 2.10.1 Fixed incomplete error on Safe.
task IncompleteErrorOnSafe {
	$file = {
		task test { throw 42 }
	}
	($r = Invoke-Build * $file -Safe | Out-String)
	assert ($r -clike 'Build test*Task /test*At *\Fixed.test.ps1:*ERROR: 42*At *\Fixed.test.ps1:*')
}

# Synopsis: #5 Invoke-Build ** -Safe propagates -Safe.
task SafeTests {
	Get-Item [z] | Remove-Item -Force -Recurse
	$null = mkdir z

	Set-Content z\1.test.ps1 {
		task task11 { 'works-11' }
		task task12 { throw 'oops-12' }
		task task23 { throw 'unexpected' }
	}

	Set-Content z\2.test.ps1 {
		task task21 { 'works-21' }
		task task22 { throw 'oops-22' }
		task task23 { throw 'unexpected' }
	}

	Invoke-Build ** z -Safe -Result r

	equals $r.Error
	equals $r.Errors.Count 2
	equals $r.Tasks.Count 4
	assert ('oops-12' -eq $r.Tasks[1].Error)
	assert ('oops-22' -eq $r.Tasks[3].Error)

	Remove-Item z -Force -Recurse
}

<#
Synopsis: A nested error should be added to results as one error.

IB used to add errors to Result.Errors for each task in a failed task chain.
2.10.4 avoids duplicated errors. But we still store an error in each task of a
failed chain. The reason is that all these tasks have failed die to this error.
On analysis of tasks Result.Tasks.Error should contain this error.
#>
task NestedErrorInResult {
	$file = {
		task t1 t2
		task t2 {throw 42}
	}

	Invoke-Build . $file -Safe -Result r

	# build failed
	equals $r.Error.FullyQualifiedErrorId '42'

	#! used to be two same errors
	equals $r.Errors.Count 1

	# but we still store an error in each task
	equals $r.Tasks.Count 2
	assert $r.Tasks[0].Error
	assert $r.Tasks[1].Error
}

# Synopsis: Fixed #12 Write-Warning fails in a trap.
# Write-Warning must be an advanced function.
task Write-Warning-in-trap {
	trap {
		Write-Warning demo-trap-warning
		continue
	}
	1/$null
}

<#
Synopsis: #17 Process all Before tasks and then process all After tasks

	Compare: Task1, Before, Task2, After:
		MSBuild test.proj /verbosity:detailed

	test.proj:
		<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
			<Target Name="Task2" DependsOnTargets="Task1"/>
			<Target Name="Task1"/>
			<Target Name="After" AfterTargets="Task2"/>
			<Target Name="Before" BeforeTargets="Task2"/>
		</Project>
#>
task AfterTaskMustBeAfterBeforeTask {
	$file = {
		task Task1
		task After -After Task1
		task Before -Before Task1
	}

	Invoke-Build . $file -Result r

	equals $r.Tasks.Count 3
	equals $r.Tasks[0].Name Before
	equals $r.Tasks[1].Name After
	equals $r.Tasks[2].Name Task1
}

# Synopsis: #20, persistent builds with cmdlet binding parameters.
task Fix20 {
	Set-Content z.build.ps1 @'
[CmdletBinding()]
param($Param1)
task good
task bad {throw 'oops'}
'@
	$r = ''
	try {Build-Checkpoint z.clixml @{Task = '*'; File = 'z.build.ps1'; Param1 = 'Fix20'}} catch {$r = $_}
	equals $r.FullyQualifiedErrorId oops

	$r = Import-Clixml z.clixml
	equals $r.Prm2.Count 1
	equals $r.Prm2.Param1 Fix20

	Remove-Item z.build.ps1, z.clixml
}

# Synopsis: #22, checkpoint before tasks
#! also covers Done = @(...)
task Fix22 {
	Set-Content z.build.ps1 {
		task test {
			if ($env:TestFix22) {
				throw 'TestFix22'
			}
			'TestFix22'
		}
	}

	# fail in the first task
	$env:TestFix22 = 1
	Build-Checkpoint z.clixml @{Task = '.'; File = 'z.build.ps1'; Safe = $true; Result = 'r'}
	assert $r.Error
	assert (Test-Path z.clixml)

	# resume
	$env:TestFix22 = ''
	Build-Checkpoint z.clixml -Resume
	assert (!(Test-Path z.clixml))
}

# Synopsis: #29, restore parameters on resume.
# Other tests did not cover this scenario.
task Fix29Resume {
	Set-Content z.ps1 {
		param($p1='default-p1')
		$Log.Add("script-$p1")
		task t1 {
			$Log.Add("task-$p1")
			throw 42
		}
	}

	$Log = [System.Collections.Generic.List[object]]@()
	Build-Checkpoint z.clixml @{File = 'z.ps1'; p1 = 'new-p1'; Safe = $true}
	equals $Log.Count 2
	equals $Log[0] script-new-p1
	equals $Log[1] task-new-p1

	$Log = [System.Collections.Generic.List[object]]@()
	Build-Checkpoint z.clixml -Resume @{Safe = $true}
	equals $Log.Count 2
	equals $Log[0] script-new-p1 #! not script-default-p1
	equals $Log[1] task-new-p1

	Remove-Item z.ps1, z.clixml
}

# v3.0.0
task InvalidCheckpointOnResume {
	($r = try {Build-Checkpoint $BuildFile -Resume} catch {$_})
	equals "$r" 'Invalid checkpoint file?'
}

# Synopsis: #34, VSTS expects $LASTEXITCODE 0 on success
task ExitCodeOnSuccessShouldBe0 {
	$file = {
		task CmdExitCode42 {
			exec {cmd.exe /c exit 42} 42
			equals $LASTEXITCODE 42
		}
	}

	Invoke-Build CmdExitCode42 $file
	equals $LASTEXITCODE 0
}

task RedefinedTask {
	# script with task t1 redefined twice
	$file = {
		task t1 {<#t1#>}
		task t1 {<#t2#>}
		task t1 {'in-last-t1'}
	}

	# build, get text and result
	($t = Invoke-Build . $file -Result r | Out-String)

	# "Redefined" message is printed twice, the last added works
	assert ($t -like "*Redefined task 't1'.*Redefined task 't1'.*in-last-t1*")

	# result has two redefined tasks
	equals $r.Redefined.Count 2
	equals $r.Redefined[0].Name t1
	equals $r.Redefined[1].Name t1
	assert $r.Redefined[0].InvocationInfo.Line.Contains('<#t1#>')
	assert $r.Redefined[1].InvocationInfo.Line.Contains('<#t2#>')
}

# In the main `catch` `${*}.Task` must be the failed task, not null. Otherwise,
# we lose `Task` in the added error info object. After the change, `${*}.Task`
# keeps the fatal task. This may be documented, if needed. [#80]
task CurrentTaskError {
	$file = {
		task Bad {
			throw 42
		}
	}

	Invoke-Build Bad $file -Safe -Result r

	equals $r.Errors.Count 1
	assert $r.Error

	$e = $r.Errors[0]
	assert $e.Task
	equals $e.Task.Name Bad
}

# Warn about always skipped double referenced tasks #82
task WarnDoubleReferenced {
	. Set-Mock Write-Warning {param($Message) $log.Add($Message)}

	$log = [System.Collections.Generic.List[object]]@()
	Invoke-Build . {
		task t1
		task t2 t1, t1
	}
	equals $log.Count 1
	equals $log[0] "Task 't2' always skips 't1'."

	$log.Clear()
	Invoke-Build . {
		task t1
		task t2 t1, ?t1
	}
	equals $log.Count 1
	equals $log[0] "Task 't2' always skips 't1'."

	$log.Clear()
	Invoke-Build . {
		task t1
		task t2 ?t1, t1
	}
	equals $log.Count 1
	equals $log[0] "Task 't2' always skips 't1'."

	$log.Clear()
	Invoke-Build . {
		task t1
		task t2 ?t1, ?t1
	}
	equals $log.Count 1
	equals $log[0] "Task 't2' always skips 't1'."
}

# If a task of a persistent build fails in its -If then the build should resume
# at this task, not at the preceding. #90
task SaveCheckpointBeforeIf {
	# This is not a proper persistent build because it depends on external $Log and $Fail.
	# But for testing it is fine.
	Set-Content z.ps1 {
		task t1 {$Log.t1 = 1}
		task t2 -If {if ($Fail) {throw 'in-if'} else {1}} {$Log.t2 = 1}
	}

	# fail in task 2 -If
	$Log = @{}
	$Fail = $true
	try {Build-Checkpoint z.clixml @{Task = '*'; File = 'z.ps1'}} catch {$_}

	# task 1 worked, task 2 did not
	equals $Log['t1'] 1
	equals $Log['t2'] $null

	# resume and let task 2 -If work
	$Log = @{}
	$Fail = $false
	Build-Checkpoint -Resume -Checkpoint z.clixml

	# task 1 skipped, task 2 worked
	equals $Log['t1'] $null
	equals $Log['t2'] 1

	Remove-Item z.ps1
}

# Test Build-Checkpoint with Safe, Summary, WhatIf
task CheckpontSafeSummaryWhatIf {
	Set-Content z.ps1 {
		task t1 {}
		task t2 {throw 'Oops'}
	}

	# test Safe and Summary
	($r = Build-Checkpoint z.clixml @{Task='*'; File='z.ps1'; Safe=$true; Summary=$true} | Out-String)
	assert ($r -like '*Oops*Build summary:*Build FAILED. 2 tasks, 1 errors, 0 warnings*')
	assert (Test-Path z.clixml)

	# test WhatIf
	($r = try {Build-Checkpoint z.clixml @{Task='*'; File='z.ps1'; WhatIf=$true}} catch {$_})
	equals $r.FullyQualifiedErrorId 'WhatIf is not supported.,Build-Checkpoint.ps1'

	Remove-Item z.ps1, z.clixml
}
