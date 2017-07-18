
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
	Remove-Item [z] -Force -Recurse
	$null = mkdir z

	{
		task task11 { 'works-11' }
		task task12 { throw 'oops-12' }
		task task23 { throw 'unexpected' }
	} > z\1.test.ps1

	{
		task task21 { 'works-21' }
		task task22 { throw 'oops-22' }
		task task23 { throw 'unexpected' }
	} > z\2.test.ps1

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
	try {Invoke-Build * z.build.ps1 -Checkpoint z.clixml -Param1 Fix20} catch {$r = $_}
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
	Invoke-Build . z.build.ps1 -Checkpoint z.clixml -Safe -Result r
	assert $r.Error
	assert (Test-Path z.clixml)

	# resume
	$env:TestFix22 = ''
	Invoke-Build -Checkpoint z.clixml -Resume
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
	Invoke-Build -File z.ps1 -p1 new-p1 -Checkpoint z.clixml -Safe
	equals $Log.Count 2
	equals $Log[0] script-new-p1
	equals $Log[1] task-new-p1

	$Log = [System.Collections.Generic.List[object]]@()
	Invoke-Build -Resume -Checkpoint z.clixml -Safe
	equals $Log.Count 2
	equals $Log[0] script-new-p1 #! not script-default-p1
	equals $Log[1] task-new-p1

	Remove-Item z.ps1, z.clixml
}

# v3.0.0
task InvalidCheckpointOnResume {
	($r = try {Invoke-Build -Checkpoint $BuildFile -Resume} catch {$_})
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
	$log = [System.Collections.Generic.List[object]]@()
	. Set-Mock Write-Warning {param($Message) $log.Add($Message)}
	Invoke-Build . {
		task . Clean, Build, Clean, Build
		task Clean {}
		task -If {1} Build {}
	}
	equals $log.Count 1
	equals $log[0] "Task '.' always skips 'Clean'."
}
