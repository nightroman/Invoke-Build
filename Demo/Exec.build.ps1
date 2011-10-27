
<#
.Synopsis
	Examples and test cases of Invoke-Exec (exec).

.Example
	Invoke-Build . Exec.build.ps1
#>

task ExecWorksCode0 {
	$script:ExecWorksCode0 = exec { cmd /c echo Code0 }
}

task ExecWorksCode42 {
	$script:ExecWorksCode42 = exec { PowerShell "'Code42'; exit 42" } (40..50)
	assert ($LastExitCode -eq 42)
}

task ExecFailsCode13 {
	exec { PowerShell "exit 13" }
}

task ExecFailsBadCommand {
	exec { throw 'Bad Command.' }
}

# The default task calls the others and tests results.
# Note use of @{} for failing tasks.
task . ExecWorksCode0, ExecWorksCode42, @{ExecFailsCode13=1}, @{ExecFailsBadCommand=1}, {

	assert ($script:ExecWorksCode0 -eq 'Code0')
	'Tested ExecWorksCode0'

	assert ($script:ExecWorksCode42 -eq 'Code42')
	'Tested ExecWorksCode42'

	$e = error ExecFailsCode13
	assert ("$e" -eq 'The command { PowerShell "exit 13" } exited with code 13.')
	'Tested ExecFailsCode13'

	$e = error ExecFailsBadCommand
	assert ("$e" -like 'Bad Command.*')
	'Tested ExecFailsBadCommand'
}
