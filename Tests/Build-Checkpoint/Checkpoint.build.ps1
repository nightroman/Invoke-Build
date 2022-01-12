<#
.Synopsis
	Persistent build with checkpoints.

.Description
	How to test interactively:
	- Invoke:
		Invoke-Build . Checkpoint.build.ps1
	- See: task1 is done, task2 runs and asks "Fail?".
	- Answer Y to fail.
	- The build fails and "checkpoint.clixml" is created.
	- Invoke again:
		Invoke-Build . Checkpoint.build.ps1
	- task1 is skipped, task2 runs and asks "Fail?".
	- Answer N to pass.
	- The build completes and "checkpoint.clixml" is gone.
#>

# Script parameters are automatically saved in checkpoints.
param(
	$Param1,
	$Param2 = 'param2'
)

# These data are shared and changed by tasks. They are saved by
# Checkpoint.Export and loaded by Checkpoint.Import.
$shared1 = 'shared1'
$shared2 = 'shared2'

# It outputs data to export to clixml. This example uses the most
# straightforward way of persisting two script variables.
Set-BuildData Checkpoint.Export {
	$shared1
	$shared2

	# (not for export) test the current location
	equals $BuildRoot (Get-Location).ProviderPath
}

# It restores data. The first argument is the last output of Checkpoint.Export.
# It is called in the script scope, variables do not have to specify the scope.
Set-BuildData Checkpoint.Import {
	$shared1, $shared2 = $args[0]
}

# Synopsis: This task works.
task task1 {
	'In task1'

	# change script data to check later they are saved and restored
	$script:shared1 += 'new'
	$script:shared2 += 'new'
	$script:param2 += 'new'

	# change the location to test saving to clixml is not affected
	Set-Location $HOME
}

# Synopsis: This task fails depending on conditions.
task task2 task1, {
	# check: on resuming shared data are restored
	equals $Param1 $null
	equals $Param2 'param2new'
	equals $shared1 'shared1new'
	equals $shared2 'shared2new'

	# non-interactive test?
	switch($env:TestCheckpointBuild) {
		pass {
			return
		}
		fail {
			throw 'Oops task2'
		}
	}

	# ask to fail
	if (Confirm-Build Fail?) {
		throw 'Oops task2'
	}
}

# Synopsis: Interactive demo of `Build-Checkpoint -Auto`.
task . {
	Build-Checkpoint -Auto checkpoint.clixml @{Task = 'task2'; File = $BuildFile}
}
