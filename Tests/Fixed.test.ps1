<#
.Synopsis
	Assorted tests and fixed issues.
#>

Import-Module .\Tools

# Synopsis: Fixed incomplete error on Safe.
# 4.1.0  prints `ERROR: <error> At <position>`, then `At <task>`
# 2.10.1 prints `At <task>`, then `ERROR: <error> At <position>`
task IncompleteErrorOnSafe {
	$file = {
		task test {
			throw 42
		}
	}
	($r = Invoke-Build * $file -Safe | Out-String)
	$r = Remove-Ansi $r
	assert ($r -cmatch '(?s)^Build test.*Task /test.*ERROR: 42.*At .*[\\/]Fixed\.test\.ps1:.*At .*[\\/]Fixed\.test\.ps1:')
}

# Synopsis: #5 Invoke-Build ** -Safe propagates -Safe.
task SafeTests {
	remove z
	$null = mkdir z

	Set-Content z/1.test.ps1 {
		task task11 { 'works-11' }
		task task12 { throw 'oops-12' }
		task task23 { throw 'unexpected' }
	}

	Set-Content z/2.test.ps1 {
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

	remove z
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
	requires -Path z.clixml

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
	try { throw Build-Checkpoint ..\LICENSE -Resume }
	catch { $_; equals "$_" 'Invalid checkpoint file?' }
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
	Set-Alias Write-Warning Write-Warning2
	function Write-Warning2 {param($Message) $log.Add($Message)}

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
	requires -Path z.clixml

	# test WhatIf
	($r = try {Build-Checkpoint z.clixml @{Task='*'; File='z.ps1'; WhatIf=$true}} catch {$_})
	equals $r.FullyQualifiedErrorId 'WhatIf is not supported.,Build-Checkpoint.ps1'

	Remove-Item z.ps1, z.clixml
}

# v4.1.0 Task with If must be invoked once and recorded once.
task ManyCallsToIf171201 {
	$file = {
		task Run -If {$toRun} {}
		task Test @(
			{$script:toRun = $false}, 'Run'
			{$script:toRun = $true}, 'Run'
			{$script:toRun = $true}, 'Run'
		)
	}

	Invoke-Build Test $file -Result r

	equals $r.Tasks.Count 2 #! not 3
	equals $r.Doubles.Count 2 # repeated 'Run'
	equals $r.Warnings.Count 0 # but no warnings due to script block conditions
}

# v4.1.0 We have such test, see Safe.test.ps1 Survives1, Survives2.
# But it was almost "fixed" instead of the regression.
task FailedSafeTaskMustBeCalledOnce171201 {
	$file = {
		task MustBeCalledOnce {throw 42}
		task CallMustBeCalledOnce1 ?MustBeCalledOnce
		task CallMustBeCalledOnce2 ?MustBeCalledOnce
		task Test CallMustBeCalledOnce1, CallMustBeCalledOnce2
	}
	Invoke-Build Test $file -Result r
	equals $r.Tasks.Count 4 #! not 5
}

# v4.1.0 The internal "current task" must be cleaned after the last task.
# Otherwise, Write-Warning may use it as current for no reason.
task CurrentTaskInExitBuild171201 {
	$file = {
		task t1 {}
		Exit-Build {
			'check the current task'
			assert ($null -eq ${*}.Task)
		}
	}
	Invoke-Build * $file
}

# v4.1.1
task EnsureResultVariable171201 {
	try {
		Invoke-Build -Result r -File missing
	}
	catch {
		$err = $_
	}

	assert $err
	assert ("$err" -like 'Missing script*')

	assert (Get-Variable r -Scope 0)
	equals $r.Error 'Invalid arguments.'
}

# v4.1.1
task EnsureResultHashtable171201 {
	try {
		$r = @{}
		Invoke-Build -Result $r -File missing
	}
	catch {
		$err = $_
	}

	assert $err
	assert ("$err" -like 'Missing script*')

	equals $r.Value.Error 'Invalid arguments.'
}

# Covers #137, Show-BuildGraph depends on (-9)
task MinusNineAsDefaultIf {
	# get tasks
	$r = Invoke-Build ?? {
		task t1
	}
	$task = $r['t1']
	equals (-9) $task.If
}

# Issue #140: Persistent builds don't seem to work
task CheckpointIssue140 {
	Set-Content z.build.ps1 {
		task B A, {
			'Invoking task B...'
		    if ($env:_190214_025531 -eq 'Fail') {throw '_190214_025531'}
		    Start-Sleep -Milliseconds 1 #! ensure Elapsed -ne [TimeSpan]::Zero
		}
		task A {
		    'Invoking task A...'
		}
	}

	# run persistent build, A works, B fails
	$fail = $null
	try {
		$env:_190214_025531 = 'Fail'
		Build-Checkpoint z.clixml -Build @{File = 'z.build.ps1'; Result = 'Result'}
	}
	catch {
		$fail = $_
	}
	equals $fail.FullyQualifiedErrorId _190214_025531
	$A = $Result.All['A']
	assert ($A.Elapsed -ne $null)
	equals $A.Error $null
	$B = $Result.All['B']
	equals $B.Error.FullyQualifiedErrorId _190214_025531

	# resume persistent build, A skips, B works
	$env:_190214_025531 = $null
	Build-Checkpoint z.clixml -Resume @{Result = 'Result'}
	$A = $Result.All['A']
	assert ($A.Elapsed -eq [TimeSpan]::Zero)
	$B = $Result.All['B']
	assert ($B.Elapsed -ne [TimeSpan]::Zero)

	# clean
	remove z.build.ps1, z.clixml
}

# Issue #142: Warning refers to child task instead of current.
task RestoreCurrentTask142 RestoreCurrentTask142Child, {
	equals RestoreCurrentTask142 ${*}.Task.Name
}
task RestoreCurrentTask142Child {}

# Issue #150: Preserve checkpoints on successful builds.
task PreserveCheckpoint {
	# good build
	Set-Content z.build.ps1 {
		task Issue150 {}
	}

	# build and preserve checkpoint
	Build-Checkpoint z.PreserveCheckpoint.clixml @{ File = 'z.build.ps1' } -Preserve

	# checkpoint has the done task
	$r = Import-Clixml z.PreserveCheckpoint.clixml
	equals $r.Done.Count 1
	equals $r.Done[0] Issue150

	# build checkpoint normally
	Build-Checkpoint z.PreserveCheckpoint.clixml @{ File = 'z.build.ps1' }

	# checkpoint is removed
	assert (!(Test-Path z.PreserveCheckpoint.clixml))

	Remove-Item z.build.ps1
}

# Issue #183, introduce $OriginalLocation, where the build starts.
task OriginalLocation {
	Set-Location $HOME
	Invoke-Build t1 {
		task t1 {
			equals $OriginalLocation $HOME
		}
	}
}

# Issue #185, pass the job in *-BuildJob
task JobAttributes {
	$log = @{log = ''}
	function Write-Host($text) {
		$log.log += $text
	}
	Invoke-Build task1 ../Tasks/Attributes/Attributes.build.ps1
	equals $log.log init1init2kill1kill2
}

# print: render lines separately. #193
task WriteAnsi {
	$text = "line1`rline2`nline3`r`nline4"
	$r = (print 0 $text) -join '|'

	if ($PSVersionTable.PSVersion -ge [Version]'7.2' -and $PSStyle.OutputRendering -ne 'PlainText') {
		equals $r "`e[30mline1`e[0m|`e[30mline2`e[0m|`e[30mline3`e[0m|`e[30mline4`e[0m"
	}
	else {
		equals $r 'line1|line2|line3|line4'
	}
}
