
if ($PSVersionTable.PSVersion.Major -lt 5) { return task forV5x }

# top level task
task test_root {
	($r = Invoke-Build root -RootParam1 RootParam1)
	assert ($r -eq 'root task RootParam1')
}

# child `build` with subtask `build-task2`
task test_build {
	($r = Invoke-Build build::build-task2 -BuildParam2 BuildParam2)
	assert ($r -eq 'build task 2 BuildParam2 ')
}

# child `deploy` with subtask `deploy-task2`
task test_deploy {
	($r = Invoke-Build deploy::deploy-task2 -deployParam2 deployParam2)
	assert ($r -eq 'deploy task 2 deployParam2 ')
}

# mix of root and child tasks, not very practical, just for fun
task test_mix {
	($r = Invoke-Build root, build::task1, deploy::task1 -CommonChildParam CommonChildParam)
	assert ($r -eq 'root task ')
	assert ($r -eq 'build task 1  CommonChildParam')
	assert ($r -eq 'deploy task 1  CommonChildParam')
}
