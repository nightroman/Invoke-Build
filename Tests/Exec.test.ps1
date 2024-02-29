<#
.Synopsis
	Tests `exec`.
#>

Import-Module .\Tools

task ExecWorksCode0 {
	$r = exec {
		if (Test-Unix) {
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
		if (Test-Unix) {
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
		if (Test-Unix) {
			exec { bash -c "exit 13" }
		}
		else {
			exec { cmd /c exit 13 }
		}
	} catch {$_}
	$r

	if (Test-Unix) {
		equals "$r" 'Command exited with code 13. { bash -c "exit 13" }'
	}
	else {
		equals "$r" 'Command exited with code 13. { cmd /c exit 13 }'
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
		if (Test-Unix) {
			exec { bash -c "exit 42" }
		}
		else {
			exec { cmd /c exit 42 }
		}
	} catch {$_}
	$r

	if (Test-Unix) {
		equals "$r" 'Command exited with code 42. { bash -c "exit 42" }'
	}
	else {
		equals "$r" 'Command exited with code 42. { cmd /c exit 42 }'
	}
}

# New switch Echo, #176 #179
task Echo1 -If ($PSVersionTable.PSVersion.Major -ge 3) {
	# different kind variables
	$env:SOME_VAR = 'SOME_VAR'
	$script:foo = 'foo'
	$bar = 'bar'

	# 1 line
	($r = exec -echo {  cmd /c echo $script:foo $env:SOME_VAR  } | Out-String)
	$r = Remove-Ansi $r
	equals $r (@(
		'exec {  cmd /c echo $script:foo $env:SOME_VAR  }'
		"cd $pwd"
		'$script:foo: foo'
		'$env:SOME_VAR: SOME_VAR'
		'foo SOME_VAR'
	) | Out-String)

	# 2+ lines
	($r = exec -echo {
		# bar
		cmd /c echo $bar $env:SOME_VAR
	} | Out-String)
	$r = Remove-Ansi $r
	equals $r (@(
		'exec {'
		'    # bar'
		'    cmd /c echo $bar $env:SOME_VAR'
		'}'
		"cd $pwd"
		'$bar: bar'
		'$env:SOME_VAR: SOME_VAR'
		'bar SOME_VAR'
	) | Out-String)

	# splatting
	$param = 'foo', 'bar', 42, 3.14, 'more'
	($r = exec { cmd /c echo @param } -echo | Out-String)
	$r = Remove-Ansi $r
	equals $r (@(
		'exec { cmd /c echo @param }'
		"cd $pwd"
		'$param: foo bar 42 3.14 more'
		'foo bar 42 3.14 more'
	) | Out-String)
}

# New parameter ErrorMessage, #178
task ErrorMessage {
	$r = Invoke-Build ?_210227_7s {
		task _210227_7s {
			exec { $global:LastExitCode = 42 } -ErrorMessage 'Demo ErrorMessage.'
		}
	}
	$r
	$r = Remove-Ansi $r
	assert ($r[2] -like 'ERROR: Demo ErrorMessage. Command exited with code 42. { $global:LastExitCode = 42 }*')
}

# #192
task Echo2 -If ($PSVersionTable.PSVersion.Major -ge 3) {
	function *Write { $args[1] }

	#! 1 line, make 1 leading and trailing space
	$r = *Echo {   foo   } | Out-String
	equals $r.TrimEnd() @"
exec {   foo   }
cd $BuildRoot
"@

	#! 1st line preserved, end spaces resolved
	$r = *Echo {foo
		bar } | Out-String
	equals $r.TrimEnd() @"
exec {foo
    bar
}
cd $BuildRoot
"@

	#! preserve leading empty, remove trailing empty, format different indents
	#! fixed `r left by split in the leading empty line
	$r = *Echo {

		if (1) {
			2
		}

	} | Out-String
	equals $r.TrimEnd() @"
exec {

    if (1) {
        2
    }
}
cd $BuildRoot
"@
}
