
<#
.Synopsis
	Assorted tests, fixed issues..

.Example
	Invoke-Build * Fixed.test.ps1
#>

Set-StrictMode -Version Latest

# Synopsis: 2.10.1 Fixed incomplete error on Safe.
task IncompleteErrorOnSafe {
	{
		; task test { throw 42 }
	} > z.build.ps1
	($r = Invoke-Build * z.build.ps1 -Safe | Out-String)
	assert ($r -clike 'Build test*Task /test*At *\z.build.ps1:2*ERROR: 42*At *\z.build.ps1:2*')
	Remove-Item z.build.ps1
}

# Synopsis: #5 Invoke-Build ** -Safe propagates -Safe.
task SafeTests {
	Remove-Item [z] -Force -Recurse
	$null = mkdir z

	{
		; task task11 { 'works-11' }
		; task task12 { throw 'oops-12' }
		; task task23 { throw 'unexpected' }
	} > z\1.test.ps1

	{
		; task task21 { 'works-21' }
		; task task22 { throw 'oops-22' }
		; task task23 { throw 'unexpected' }
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
	{
		; task t1 t2
		; task t2 {throw 42}
	} > z.build.ps1

	Invoke-Build . z.build.ps1 -Safe -Result r

	# build failed
	equals $r.Error.FullyQualifiedErrorId '42'

	#! used to be two same errors
	equals $r.Errors.Count 1

	# but we still store an error in each task
	equals $r.Tasks.Count 2
	assert $r.Tasks[0].Error
	assert $r.Tasks[1].Error

	Remove-Item z.build.ps1
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
	{
		; task Task1
		; task After -After Task1
		; task Before -Before Task1
	} > z.build.ps1

	Invoke-Build . z.build.ps1 -Result r

	equals $r.Tasks.Count 3
	equals $r.Tasks[0].Name Before
	equals $r.Tasks[1].Name After
	equals $r.Tasks[2].Name Task1

	Remove-Item z.build.ps1
}
