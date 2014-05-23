
<#
.Synopsis
	Custom task tests.

.Example
	Invoke-Build * Custom.test.ps1
#>

# Synopsis: Test the custom task "test".
task Test {
	Invoke-Build * ..\Tasks\Test\Test.build.ps1 -Result r
	assert ($r.Tasks.Count -eq 8)
	assert ($r.Errors.Count -eq 4)
}

# Synopsis: Test "check", pass all, then run again.
task Check1 {
	$file = '..\Tasks\Check\Check.build.ps1.Check.clixml'
	Remove-Item $file -ErrorAction 0

	# fake to pass all
	function Read-Host {}

	Invoke-Build * ..\Tasks\Check\Check.build.ps1 -Result r
	assert ($r.Tasks.Count -eq 6)
	assert (Test-Path $file)

	Invoke-Build * ..\Tasks\Check\Check.build.ps1 -Result r
	assert ($r.Tasks.Count -eq 1)

	Remove-Item $file
}

# Synopsis: Test "check", fail at task.2.2, then run again.
task Check2 {
	$file = '..\Tasks\Check\Check.build.ps1.Check.clixml'
	Remove-Item $file -ErrorAction 0

	# fake to fail at task.2.2
	function Read-Host {
		if ($args[0] -eq 'Do task.2.2 and press enter') {throw 'Demo error'}
	}

	Invoke-Build * ..\Tasks\Check\Check.build.ps1 -Result r -Safe
	assert ($r.Error)
	assert ($r.Tasks.Count -eq 6)
	assert ($r.Errors.Count -eq 2)
	assert (Test-Path $file)

	# fake to pass all
	function Read-Host {}

	Invoke-Build * ..\Tasks\Check\Check.build.ps1 -Result r
	assert ($r.Tasks.Count -eq 2)

	Remove-Item $file
}
