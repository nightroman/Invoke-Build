
task test1 {
	$global:task_clean = ''
	$global:task_build = ''

	./Test-1-bug.ps1

	equals $global:task_clean $true
	equals $global:task_build ''
}

task test2 {
	$global:task_clean = ''
	$global:task_build = ''

	./Test-2-ok.ps1

	equals $global:task_clean $true
	equals $global:task_build $true
}

task test3 {
	$global:task_clean = ''
	$global:task_build = ''

	./Test-3-ok.ps1

	equals $global:task_clean $true
	equals $global:task_build $true
}
