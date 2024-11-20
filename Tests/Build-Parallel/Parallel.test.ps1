<#
.Synopsis
	Tests parallel builds called by Build-Parallel.
#>

Import-Module ..\Tools

# The build engine defines aliases Invoke-Build and Build-Parallel
task Alias {
	#! also covers 1.2.0, see notes
	$alias1 = Get-Alias Invoke-Build
	$alias2 = Get-Alias Build-Parallel
	equals $alias2.Definition (Join-Path (Split-Path $alias1.Definition) Build-Parallel.ps1)
}

# 1. Build-Parallel with 0 builds is allowed (but this is not normal).
# 2. Get the build result using a hashtable.
task NoBuilds {
	$Result = @{}
	Build-Parallel -Result $Result
	equals $Result.Value.Tasks.Count 0
}

# 1. Build-Parallel with 1 build is allowed (but this is not normal).
# 2. Get the build result using the [ref] variable.
task OneBuild {
	$Result = @{}
	Build-Parallel @{File='..\Dynamic.build.ps1'} -Result $Result
	equals $Result.Value.Tasks.Count 5
}

<#
Invoke several builds (normal scenario) with one of them failing (it happens).
Each build is defined by a table with the mandatory entry 'File' and optional
'Task' and 'Parameters'. They are used as Invoke-Build parameters.

Four parallel builds of this test could be invoked as simple as this

	Build-Parallel @(
		@{File='..\Dynamic.build.ps1'}
		@{File='..\Safe.test.ps1'; Task='Error1'}
		@{File='..\Dynamic.build.ps1'; Task='Task0'}
		@{File='..\Conditional.build.ps1'; Parameters=@{Configuration='Debug'}}
	)

But we use more steps in order to test the details and show techniques for
advanced build result analysis.
#>
task Many {
	# These build parameter tables are not changed (to be tested).
	$build0 = @{File='..\Dynamic.build.ps1'}
	$build1 = @{File='..\Safe.test.ps1'; Task='Error1'}
	$build2 = @{File='..\Dynamic.build.ps1'; Task='Task0'}
	$build3 = @{File='..\Conditional.build.ps1'; Configuration='Debug'}

	# But these items will be replaced with copied and amended tables:
	# File is resolved to its full path, added Result contains build results.
	# NOTE: if [hashtable[]] is omitted then the $build is not changed because
	# PowerShell converts it to [hashtable[]] and the copy is actually changed.
	[hashtable[]]$build = $build0, $build1, $build2, $build3

	# As far as it is going to fail due to $build1, use try..catch.
	# Get the results using the variable name.
	$message = ''
	try {
		Build-Parallel -Build $build -ShowParameter Task -Result Result
	}
	catch {
		$message = "$_"
		Write-Build Magenta $message
	}

	# Joined results
	equals $Result.Tasks.Count 8
	equals $Result.Errors.Count 1

	# Input data not changed.
	equals $build0.File '..\Dynamic.build.ps1'

	# But copies have amended and new data:
	# - File is resolved to full path
	assert ([System.IO.Path]::IsPathRooted($build[0].File))
	# - Result is added
	assert ($build[0].Result.Value)

	# The call itself failed.
	assert ($message -like "Failed builds:*Build: *$(Get-Separator)Safe.test.ps1*ERROR: Error1*At *$(Get-Separator)Safe.test.ps1:*")

	# Check each build error; note that 3 builds succeeded because the
	# parallel build engine lets all builds to work, even if some fail.
	equals $build[0].Result.Value.Error $null # OK
	assert $build[1].Result.Value.Error # ERROR
	equals $build[2].Result.Value.Error $null # OK
	equals $build[3].Result.Value.Error $null # OK

	# Check result task counts.
	equals $build[0].Result.Value.Tasks.Count 5
	equals $build[1].Result.Value.Tasks.Count 1
	equals $build[2].Result.Value.Tasks.Count 1
	equals $build[3].Result.Value.Tasks.Count 1
}

<#
Invoke three builds with the specified timeout. The first build should
complete, the other two should be stopped by the engine due to timeout.
#>
task Timeout {
	$message = ''
	try {
		Build-Parallel -Result r -Timeout 500 @(
			@{File='Parallel.build.ps1'; Task='Sleep'; SleepMilliseconds=10; Log='z.1'}
			@{File='Parallel.build.ps1'; Task='Sleep'; SleepMilliseconds=2000; Log='z.2'}
			@{File='Parallel.build.ps1'; Task='Sleep'; SleepMilliseconds=3000; Log='z.3'}
		)
	}
	catch {
		$message = "$_"
	}
	Write-Build Magenta $message

	# Check the error message.
	assert ((Format-LF $message) -like (Format-LF @'
Failed builds:
Build: *Parallel.build.ps1
ERROR: Build timed out.
Build: *Parallel.build.ps1
ERROR: Build timed out.*
'@))

	# Check the log files: the first is complete, the others are not.
	$build_succeeded = 'Build succeeded. 1 tasks, 0 errors, 0 warnings *'
	# log 1
	$lines = Get-Content z.1 | .{process{ Remove-Ansi $_ }}
	assert ($lines -contains 'end - конец')
	assert ($lines[-1] -like $build_succeeded)
	# log 2 and 3
	assert (!(Test-Path z.2) -or (Get-Content z.2)[-1] -notlike $build_succeeded)
	assert (!(Test-Path z.3) -or (Get-Content z.3)[-1] -notlike $build_succeeded)
	Remove-Item z.?

	# v4.1.1 Was 3. We now drop incomplete results.
	equals $r.Tasks.Count 1
}

# Error: invalid MaximumBuilds
task ParallelBadMaximumBuilds {
	Build-Parallel -MaximumBuilds 0 @{File='..\Dynamic.build.ps1'}
}

# Error: Invoke-Build.ps1 is not in the same directory.
# Covers #27, *Die was not found before loading IB.
task ParallelMissingEngine -If (!$env:GITHUB_ACTION) {
	remove z
	$null = mkdir z
	Copy-Item ..\..\Build-Parallel.ps1 z

	$command = @"
`$global:ErrorView = 'NormalView'
& 'z/Build-Parallel.ps1' @{bar=1}
"@

	($r = Invoke-PowerShell -NoProfile -Command $command | Out-String)
	assert ($r -like "*Invoke-Build.ps1'*@{bar=1}*CommandNotFoundException*")
	remove z
}

# Error: missing script
task ParallelMissingFile {
	Build-Parallel @{File='MissingFile'}
}

# Error: invalid Parameters type on calling Build-Parallel
task ParallelBadParameters {
	Build-Parallel @{File='..\Dynamic.build.ps1'; Parameters=42}
}

# Test error cases.
task ParallelErrorCases ?ParallelMissingFile, ?ParallelBadMaximumBuilds, ?ParallelBadParameters, {
	Test-Error (Get-BuildError ParallelMissingFile) "Missing script '*MissingFile'.*@{File='MissingFile'}*ObjectNotFound*"
	Test-Error (Get-BuildError ParallelBadMaximumBuilds) "MaximumBuilds should be a positive number.*-MaximumBuilds 0*InvalidArgument*"
	Test-Error (Get-BuildError ParallelBadParameters) "Failed builds:*Build: *Dynamic.build.ps1*ERROR: Invalid build arguments or script. Error: *parameter name 'Parameters'*"
}

# v2.0.1 - It is fine to omit the key File in build parameters.
task OmittedBuildParameterFile {
	remove z
	$null = mkdir z

	# new build script; its default task calls two parallel builds in the same script
	Set-Content z/.build.ps1 {
		task t1 { 'out 1' }
		task t2 { 'out 2'; Start-Sleep 1 }
		task . { Build-Parallel @{Task='t1'}, @{Task='t2'} }
	}

	Push-Location z
	Invoke-Build -Result result

	$r = $result.Tasks
	equals $r.Count 3
	equals $r[0].Name t1
	equals $r[1].Name t2
	equals $r[2].Name .

	Pop-Location
	remove z
}

# Covers #27, [IB] was not found before loading IB.
task ParallelEmptyRun {
	($r = Invoke-PowerShell -NoProfile -Command 'Build-Parallel.ps1 -Result r; $r.GetType().Name')
	equals $r PSCustomObject
}

# Covers #93 with the new switch FailHard.
task FailHard -If (!$env:GITHUB_ACTION) {
	# task script
	Set-Content z.build.ps1 {
		task t1 { Start-Sleep 100 }
		task t2 { throw 13 }
		task t3 { }
	}

	# unofficial way to get individual build results
	[hashtable[]]$build = @(
		@{File='z.build.ps1'; Task='t1'}
		@{File='z.build.ps1'; Task='t2'}
		@{File='z.build.ps1'; Task='t3'}
	)

	# invoke 3 parallel builds
	$null = try {Build-Parallel -FailHard -MaximumBuilds 2 -Build $build -Result result} catch {$_}

	# unofficial results
	# has Result but no Error, started and aborted
	equals $build[0].Result.Value.Error
	# has Result and Error, started and failed
	equals $build[1].Result.Value.Error.FullyQualifiedErrorId '13'
	# has no Result, not started
	equals $build[2].Result.ContainsKey('Value') $false

	# official result
	$r = $result.Tasks
	# one failed task t2, t1 aborted, t3 not started
	equals $r.Count 1
	equals $r[0].Name t2
	assert ($null -ne $r[0].Elapsed)
	equals $r[0].Error.FullyQualifiedErrorId '13'

	Remove-Item z.build.ps1
}
