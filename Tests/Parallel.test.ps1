
<#
.Synopsis
	Tests parallel builds called by Build-Parallel

.Example
	Invoke-Build * Parallel.test.ps1
#>

. .\Shared.ps1

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
	#?? V3 does not return anything via [ref]
	if ($PSVersionTable.PSVersion.Major -ge 3) {
		$Result = @{}
	}
	else {
		$Result = [ref]$null
	}
	Build-Parallel @{File='Dynamic.build.ps1'} -Result $Result
	equals $Result.Value.Tasks.Count 5
}

<#
Invoke several builds (this is normal scenario) with one of them failing (it
happens and should be tested as well). Each build is defined by a hash with the
mandatory entry 'File' and optional 'Task' and 'Parameters'. These File, Task,
and Parameters are used as Invoke-Build parameters.

Four parallel builds of this test could be invoked as simple as this

	Build-Parallel @(
		@{File='Dynamic.build.ps1'}
		@{File='Safe.test.ps1'; Task='Error1'}
		@{File='Dynamic.build.ps1'; Task='Task0'}
		@{File='Conditional.build.ps1'; Parameters=@{Configuration='Debug'}}
	)

The test itself does this in much more steps in order to test all the details.
In most cases the code should not be like test. But this test code shows
techniques useful for advanced build result analysis.
#>
task Many {
	# These build parameter hashes are not changed (to be tested).
	$build0 = @{File='Dynamic.build.ps1'}
	$build1 = @{File='Safe.test.ps1'; Task='Error1'}
	$build2 = @{File='Dynamic.build.ps1'; Task='Task0'}
	$build3 = @{File='Conditional.build.ps1'; Configuration='Debug'}

	# But this array items will be replaced with copied and amended hashes:
	# File is resolved to its full path, added Result contains build results.
	# NOTE: if [hashtable[]] is omitted then the $build is not changed because
	# PowerShell converts it to [hashtable[]] and the copy is actually changed.
	[hashtable[]]$build = $build0, $build1, $build2, $build3

	# As far as it is going to fail due to $build1, use try..catch.
	# Get the results using the variable name.
	$message = ''
	try {
		Build-Parallel -Build $build -Result Result
	}
	catch {
		$message = "$_"
		Write-Build Magenta $message
	}

	# Joined results
	equals $Result.Tasks.Count 8
	equals $Result.Errors.Count 1

	# Input hashes was not changed.
	equals $build0.File 'Dynamic.build.ps1'

	# But their copies have amended and new data, for example, File were
	# resolved to full paths and Result entries were added.
	assert ($build[0].File -like '*\Dynamic.build.ps1')
	assert ($build[0].Result.Value)

	# The call itself failed.
	assert ($message -like "Failed builds:*Build: *\Safe.test.ps1*ERROR: Error1*At *\Safe.test.ps1:*")

	# Check each build error; note that three builds succeeded because the
	# parallel build engine lets all builds to work, even if some fail.
	equals $build[0].Result.Value.Error # No error
	assert $build[1].Result.Value.Error # ERROR
	equals $build[2].Result.Value.Error # No error
	equals $build[3].Result.Value.Error # No error

	# Check for task count in the results.
	equals $build[0].Result.Value.Tasks.Count 5
	equals $build[1].Result.Value.Tasks.Count 1
	equals $build[2].Result.Value.Tasks.Count 1
	equals $build[3].Result.Value.Tasks.Count 1
}

<#
Invoke three builds with the specified timeout. The first build should
complete, the other two should be stopped by the engine due to timeout.

Skip this task in problem paths:
https://connect.microsoft.com/PowerShell/feedback/details/708432
#>
task Timeout -If ($BuildRoot -notmatch '[\[\]]') {
	# Invoke using try..catch because it fails and use log files for outputs.
	$message = ''
	try {
		Build-Parallel -Timeout 500 @(
			@{File='Sleep.build.ps1'; Milliseconds=10; Log='z.1'}
			@{File='Sleep.build.ps1'; Milliseconds=2000; Log='z.2'}
			@{File='Sleep.build.ps1'; Milliseconds=3000; Log='z.3'}
		)
	}
	catch {
		$message = "$_"
	}

	# Check the error message.
	assert ($message -like @'
Failed builds:
Build: *\Sleep.build.ps1
ERROR: Build timed out.
Build: *\Sleep.build.ps1
ERROR: Build timed out.*
'@) "[[$message]]"

	# Check the log files: the first is complete, the others are not.
	assert ((Get-Content z.1)[-1] -like 'Build succeeded. 1 tasks, 0 errors, 0 warnings *')
	assert (!(Test-Path z.2) -or (Get-Content z.2)[-1] -eq 'begin - начало')
	assert (!(Test-Path z.2) -or (Get-Content z.3)[-1] -eq 'begin - начало')
	Remove-Item z.?
}

# Error: invalid MaximumBuilds
task ParallelBadMaximumBuilds {
	Build-Parallel -MaximumBuilds 0 @{File='Dynamic.build.ps1'}
}

# Error: Invoke-Build.ps1 is not in the same directory.
# Covers #27, *Die was not found before loading IB.
task ParallelMissingEngine {
	$script = "$env:TEMP\Build-Parallel.ps1"
	Copy-Item ..\Build-Parallel.ps1 $script -Force

	($r = Invoke-PowerShell -NoProfile -Command "& '$script' @{bar=1}" | Out-String)

	[System.IO.File]::Delete($script)
	assert ($r -like "*'$env:TEMP\Invoke-Build.ps1'*@{bar=1}*CommandNotFoundException*")
}

# Error: missing script
task ParallelMissingFile {
	Build-Parallel @{File='MissingFile'}
}

# Error: invalid Parameters type on calling Build-Parallel
task ParallelBadParameters {
	Build-Parallel @{File='Dynamic.build.ps1'; Parameters='BadParameters'}
}

# Test error cases.
task ParallelErrorCases @(
	'?ParallelMissingFile'
	'?ParallelBadMaximumBuilds'
	'?ParallelBadParameters'
	{
		Test-Error ParallelMissingFile "Missing script '*\MissingFile'.*@{File='MissingFile'}*ObjectNotFound*"
		Test-Error ParallelBadMaximumBuilds "MaximumBuilds should be a positive number.*-MaximumBuilds 0*InvalidArgument*"
		Test-Error ParallelBadParameters "Failed builds:*Build: *\Dynamic.build.ps1*ERROR: *parameter name 'Parameters'*"
	}
)

# v2.0.1 - It is fine to omit the key File in build parameters.
task OmittedBuildParameterFile {
	# new temp directory
	$null = mkdir z -Force

	# new build script; its default task calls two parallel builds in the same script
	Set-Content z\.build.ps1 {
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
	Remove-Item z -Recurse
}

# Covers #27, [IB] was not found before loading IB.
task ParallelEmptyRun {
	$version = $PSVersionTable.PSVersion.Major
	($r = Invoke-PowerShell -NoProfile -Command 'Build-Parallel.ps1 -Result r; $r.GetType().Name')
	equals $r $(if ($version -eq 2) {'Hashtable'} else {'PSCustomObject'})
}

# Covers #93 with the new switch FailHard.
task FailHard {
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
	# two tasks started
	$r = $result.Tasks
	equals $r.Count 2
	# t1 started but not finished
	equals $r[0].Name t1
	equals $r[0].Elapsed
	equals $r[0].Error
	# t2 started and failed
	equals $r[1].Name t2
	assert ($null -ne $r[1].Elapsed)
	equals $r[1].Error.FullyQualifiedErrorId '13'

	Remove-Item z.build.ps1
}
