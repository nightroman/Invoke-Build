
<#
.Synopsis
	Tests a persistent build.

.Example
	# Choose break or continue at the task2
	Invoke-Build . Checkpoint.build.ps1

.Example
	# Resume the broken build at the task2
	Invoke-Build resume Checkpoint.build.ps1
#>

param($Test)

# These data are shared and changed by tasks. They have to be persisted using
# event functions Export-Build and Import-Build.
$shared1 = 'shared1'
$shared2 = 'shared2'

# It outputs data to be exported to clixml. This example uses the most
# straightforward way of persisting two script variables.
function Export-Build {
	$shared1
	$shared2
	assert ($BuildRoot -eq (Get-Location).ProviderPath)
}

# It restores data. The first argument is the output of Export-Build exported to
# clixml and then imported back. This example uses the most straightforward way
# of persisting two script variables. Note: Import-Build is invoked in the
# script scope and variable names do not have to use the prefix `script:`.
function Import-Build {
	$shared1, $shared2 = $args[0]
}

task task1 {
	'In task1'

	# change the script data in order to check later that new data are saved to
	# and then restored from the clixml file
	$script:shared1 += 'new'
	$script:shared2 += 'new'

	# change the location, this should not break saving to clixml even if the
	# parameter Checkpoint has not been defined as a full path
	Set-Location $HOME
}

task task2 task1, {
	# check: shared data are restored
	assert ($shared1 -eq 'shared1new')
	assert ($shared2 -eq 'shared2new')

	if (!$Test) {
		# interactive break or continue
		Read-Host 'In task2: Ctrl-C: break; Enter: continue'
	}
	elseif ($env:ResumeBuild) {
		# non interactive continue
		'Resumed task2'
	}
	else {
		# non interactive break
		throw 'Oops task2'
	}
}

# Interactive demo.
task . {
	Invoke-Build task2 Checkpoint.build.ps1 -Checkpoint checkpoint.clixml
}

# Test resume at the task2. Note: -Checkpoint is used alone for resuming.
task resume {
	$env:ResumeBuild = 1
	Invoke-Build -Checkpoint checkpoint.clixml
	$env:ResumeBuild = $null
}

# Test non interactive break in the task2.
task break {
	#! issue: use 2 tasks
	Invoke-Build task1, task2 Checkpoint.build.ps1 @{Test=$true} -Checkpoint checkpoint.clixml
}

# Tests the code used for clixml export and import
task TestSerialization {
	&{
		$task = [string[]]'t1'
		$file = [string]'f1'
		$parameters = $null
		$load = 't1'
		$data = {}
		$(,$task; $file; $parameters; ,@(foreach($_ in $load){$_}); & $data) | Export-Clixml z.clixml
	}
	&{
		$task, $file, $parameters, $load, $data = Import-Clixml z.clixml
		assert ($task -is [System.Collections.ArrayList] -and $task.Count -eq 1 -and $task[0] -eq 't1')
		assert ($file -is [string] -and $file -eq 'f1')
		assert ($null -eq $parameters)
		assert ($load -is [System.Collections.ArrayList] -and $load.Count -eq 1 -and $load[0] -eq 't1')
		assert ($null -eq $data)
	}
	&{
		$task = [string[]]('t1', 't2')
		$file = [string]'f1'
		$parameters = @{p1=11}
		$load = @('t1', 't2')
		$data = {22, 33, 44}
		$(,$task; $file; $parameters; ,@(foreach($_ in $load){$_}); & $data) | Export-Clixml z.clixml
	}
	&{
		$task, $file, $parameters, $load, $data = Import-Clixml z.clixml
		assert ($task -is [System.Collections.ArrayList] -and $task.Count -eq 2)
		assert ($file -is [string] -and $file -eq 'f1')
		assert ($parameters -is [hashtable] -and $parameters.Count -eq 1)
		assert ($load -is [System.Collections.ArrayList] -and $load.Count -eq 2)
		assert ($data -is [object[]] -and $data.Count -eq 3)
	}
	Remove-Item z.clixml
}

# This is a test. Call the task `break` as protected because it fails. The
# checkpoint should be created, as a result. Then call the task `resume` and
# check that the checkpoint has been deleted.
task test TestSerialization, @{break=1}, {assert (Test-Path checkpoint.clixml)}, resume, {assert !(Test-Path checkpoint.clixml)}
