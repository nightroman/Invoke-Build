
<#
.Synopsis
	Examples and tests of `exec`.

.Example
	Invoke-Build * Exec.test.ps1
#>

task ExecWorksCode0 {
	$r = exec { cmd /c echo Code0 }
	equals $r Code0
	equals $global:LastExitCode 0
}

task ExecWorksCode42 {
	$r = exec { cmd /c 'echo Code42&& exit 42' } (40..50)
	equals $r Code42
	equals $global:LastExitCode 42
}

task ExecFailsCode13 {
	($r = try {exec { cmd /c exit 13 }} catch {$_})
	assert (($r | Out-String) -like 'exec : Command { cmd /c exit 13 } exited with code 13.*At *\Exec.test.ps1:*')
}

task ExecFailsBadCommand {
	($r = try {exec { throw 'throw in ExecFailsBadCommand' }} catch {$_})
	#! v2/v5
	assert (($r | Out-String) -like '*throw in ExecFailsBadCommand*At *\Exec.test.ps1:*')
}

# Issue #54.
task ExecShouldUseGlobalLastExitCode {
	# troublesome code
	$LASTEXITCODE = 0

	# should fail regardless of local $LASTEXITCODE
	($r = try {exec { cmd /c exit 42 }} catch {$_})
	equals "$r" 'Command { cmd /c exit 42 } exited with code 42.'
}
