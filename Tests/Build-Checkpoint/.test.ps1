
task Auto {
	# init
	remove z.clixml

	# the same -Build for 2 calls with -Auto
	$build = @{Task = 'task2'; File = 'Checkpoint.build.ps1'}

	# call 1 fails
	try {
		$env:TestCheckpointBuild = 'fail'
		Build-Checkpoint -Auto z.clixml $build
		throw
	}
	catch {
		$err = $_
	}
	equals "$err" 'Oops task2'
	assert (Test-Path z.clixml)

	# call 2 works
	$env:TestCheckpointBuild = 'pass'
	Build-Checkpoint -Auto z.clixml $build
	assert (!(Test-Path z.clixml))

	# kill
	remove z.clixml
	$env:TestCheckpointBuild = $null
}

task Resume {
	# init
	remove z.clixml

	# call 1 fails
	try {
		$env:TestCheckpointBuild = 'fail'
		Build-Checkpoint z.clixml @{Task = 'task2'; File = 'Checkpoint.build.ps1'}
		throw
	}
	catch {
		$err = $_
	}
	equals "$err" 'Oops task2'
	assert (Test-Path z.clixml)

	# call 2 works, NB -Build is not required
	$env:TestCheckpointBuild = 'pass'
	Build-Checkpoint -Resume z.clixml
	assert (!(Test-Path z.clixml))

	# kill
	remove z.clixml
	$env:TestCheckpointBuild = $null
}

task ResumeShouldFailOnMissingFile {
	try {
		Build-Checkpoint -Resume missing.clixml
		throw
	}
	catch {
		$err = $_
	}
	equals "$err" "Missing checkpoint '$BuildRoot\missing.clixml'."
}

# Tests the code used for clixml export and import
task Serialization {
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
		assert ($task -is [System.Collections.ArrayList])
		equals $task.Count 1
		equals $task[0] t1
		equals $file f1
		equals $parameters
		assert ($load -is [System.Collections.ArrayList])
		equals $load.Count 1
		equals $load[0] t1
		equals $data
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
		assert ($task -is [System.Collections.ArrayList])
		equals $task.Count 2
		equals $file f1
		assert ($parameters -is [hashtable])
		equals $parameters.Count 1
		assert ($load -is [System.Collections.ArrayList])
		equals $load.Count 2
		assert ($data -is [object[]])
		equals $data.Count 3
	}
	Remove-Item z.clixml
}
