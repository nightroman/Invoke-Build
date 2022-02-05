
# Synopsis: Test "check", pass all, then run again.
task Check1 {
	$file = 'Check.build.ps1.Check.clixml'
	remove $file

	# fake to pass all
	function Read-Host {}

	Invoke-Build * Check.build.ps1 -Result r
	equals $r.Tasks.Count 6
	requires -Path $file

	Invoke-Build * Check.build.ps1 -Result r
	equals $r.Tasks.Count 1

	Remove-Item $file
}

# Synopsis: Test "check", fail at task.2.2, then run again.
task Check2 {
	$file = 'Check.build.ps1.Check.clixml'
	remove $file

	# fake to fail at task.2.2
	function Read-Host {
		if ($args[0] -eq 'Do task.2.2 and press enter') {throw 'Demo error'}
	}

	Invoke-Build * Check.build.ps1 -Result r -Safe
	assert ($r.Error)
	equals $r.Tasks.Count 6
	equals $r.Errors.Count 1
	requires -Path $file

	# fake to pass all
	function Read-Host {}

	Invoke-Build * Check.build.ps1 -Result r
	equals $r.Tasks.Count 2

	Remove-Item $file
}
