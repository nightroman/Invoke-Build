
<#
.Synopsis
	Tests parallel builds called by Invoke-Builds

.Example
	Invoke-Build * Parallel.build.ps1
#>

# The build engine defines aliases Invoke-Build and Invoke-Builds
task Alias {
	#! also covers 1.2.0, see notes
	$alias1 = Get-Alias Invoke-Build
	$alias2 = Get-Alias Invoke-Builds
	assert ($alias2.Definition -eq (Join-Path (Split-Path $alias1.Definition) Invoke-Builds.ps1))
}

# 1. Invoke-Builds with 0 builds is allowed (but this is not normal).
# 2. Get the build result using a hashtable.
task NoBuilds {
	$Result = @{}
	Invoke-Builds -Result $Result
	assert ($Result.Value.Tasks.Count -eq 0)
}

# 1. Invoke-Builds with 1 build is allowed (but this is not normal).
# 2. Get the build result using the [ref] variable.
task OneBuild {
	$Result = [ref]$null
	Invoke-Builds @{File='Dynamic.build.ps1'} -Result $Result
	assert ($Result.Value.Tasks.Count -eq 5)
}

<#
Invoke several builds (this is normal scenario) with one of them failing (it
happens and should be tested as well). Each build is defined by a hash with the
mandatory entry 'File' and optional 'Task' and 'Parameters'. These File, Task,
and Parameters are used as Invoke-Build parameters.

Four parallel builds of this test could be invoked as simple as this

	Invoke-Builds @(
		@{File='Dynamic.build.ps1'}
		@{File='ErrorCases.build.ps1'}
		@{File='Dynamic.build.ps1'; Task='Task1'}
		@{File='Conditional.build.ps1'; Parameters=@{Configuration='Debug'}}
	)

The test itself does this in much more steps in order to test all the details.
In most cases the code should not be like test. But this test code shows
techniques useful for advanced build result analysis.
#>
task Many {
	# These build parameter hashes are not changed (to be tested).
	$build0 = @{File='Dynamic.build.ps1'}
	$build1 = @{File='ErrorCases.build.ps1'}
	$build2 = @{File='Dynamic.build.ps1'; Task='Task1'}
	$build3 = @{File='Conditional.build.ps1'; Parameters=@{Configuration='Debug'}}

	# But this array items will be replaced with copied and amended hashes:
	# File is resolved to its full path, added Result contains build results.
	# NOTE: if [hashtable[]] is omitted then the $build is not changed because
	# PowerShell converts it to [hashtable[]] and the copy is actually changed.
	[hashtable[]]$build = $build0, $build1, $build2, $build3

	# As far as it is going to fail due to $build1, use try..catch.
	# Get the results using the variable name.
	$message = ''
	try {
		Invoke-Builds -Build $build -Result Result #@{Configuration='Release'}
	}
	catch {
		$message = "$_"
		Write-BuildText Magenta $message
	}

	# Joined results
	assert (8 -eq $Result.Tasks.Count)
	assert (1 -eq $Result.ErrorCount)

	# Input hashes was not changed.
	assert ($build0.File -eq 'Dynamic.build.ps1')

	# But their copies have amended and new data, for example, File were
	# resolved to full paths and Result entries were added.
	assert ($build[0].File -like '*\Dynamic.build.ps1')
	assert ($build[0].Result.Value)

	# The call itself failed.
	assert ($message -like "Parallel build failures:*Build: *\ErrorCases.build.ps1*ERROR: Error1*At *\SharedTasksData.tasks.ps1:*")

	# Check each build error; note that three builds succeeded because the
	# parallel build engine lets all builds to work, even if some fail.
	assert ($null -eq $build[0].Result.Value.Error) # No error
	assert ($null -ne $build[1].Result.Value.Error) # ERROR
	assert ($null -eq $build[2].Result.Value.Error) # No error
	assert ($null -eq $build[3].Result.Value.Error) # No error

	# Check for task count in the results.
	assert (5 -eq $build[0].Result.Value.Tasks.Count)
	assert (1 -eq $build[1].Result.Value.Tasks.Count)
	assert (1 -eq $build[2].Result.Value.Tasks.Count)
	assert (1 -eq $build[3].Result.Value.Tasks.Count)
}
