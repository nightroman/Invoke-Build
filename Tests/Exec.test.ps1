<#
.Synopsis
	Tests `exec`.

.Example
	Invoke-Build * Exec.test.ps1
#>

. ./Shared.ps1

task ExecWorksCode0 {
	$r = exec {
		if ($IsUnix) {
			bash -c 'echo Code0'
		}
		else {
			cmd /c echo Code0
		}
	}
	equals $r Code0
	equals $global:LastExitCode 0
}

task ExecWorksCode42 {
	$r = exec {
		if ($IsUnix) {
			bash -c 'echo Code42&& exit 42'
		}
		else {
			cmd /c 'echo Code42&& exit 42'
		}
	} (40..50)
	equals $r Code42
	equals $global:LastExitCode 42
}

task ExecFailsCode13 {
	$r = try {
		if ($IsUnix) {
			exec { bash -c "exit 13" }
		}
		else {
			exec { cmd /c exit 13 }
		}
	} catch {$_}
	$r

	if ($IsUnix) {
		equals "$r" 'Command { bash -c "exit 13" } exited with code 13.'
	}
	else {
		equals "$r" 'Command { cmd /c exit 13 } exited with code 13.'
	}
	equals $r.InvocationInfo.ScriptName $BuildFile
}

task ExecFailsBadCommand {
	($r = try {exec { throw 'throw in ExecFailsBadCommand' }} catch {$_})
	assert ($r.InvocationInfo.Line.Contains('throw in ExecFailsBadCommand'))
}

# Issue #54.
task ExecShouldUseGlobalLastExitCode {
	# troublesome code
	$LASTEXITCODE = 0

	# should fail regardless of local $LASTEXITCODE
	$r = try {
		if ($IsUnix) {
			exec { bash -c "exit 42" }
		}
		else {
			exec { cmd /c exit 42 }
		}
	} catch {$_}
	$r

	if ($IsUnix) {
		equals "$r" 'Command { bash -c "exit 42" } exited with code 42.'
	}
	else {
		equals "$r" 'Command { cmd /c exit 42 } exited with code 42.'
	}
}
