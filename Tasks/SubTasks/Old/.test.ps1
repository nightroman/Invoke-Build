
# top level task
task test_root {
	($r = ./root.build.ps1 root -RootParam1 RootParam1)
	assert ($r -eq 'root task RootParam1')
}

# child `build` with subtask `build-task2`
task test_build {
	($r = ./root.build.ps1 build build-task2 -BuildParam2 BuildParam2)
	assert ($r -eq 'build task 2 BuildParam2 ')
}

# child `deploy` with subtask `deploy-task2`
task test_deploy {
	($r = ./root.build.ps1 deploy deploy-task2 -deployParam2 deployParam2)
	assert ($r -eq 'deploy task 2 deployParam2 ')
}

# mix of root and child tasks, not very practical, just for fun
task test_mix {
	($r = ./root.build.ps1 root, build, deploy task1 -CommonChildParam CommonChildParam)
	assert ($r -eq 'root task ')
	assert ($r -eq 'build task 1  CommonChildParam')
	assert ($r -eq 'deploy task 1  CommonChildParam')
}
