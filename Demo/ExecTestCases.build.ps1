
<#
.Synopsis
	Examples and test cases of Invoke-Exec (exec).

.Link
	.build.ps1
#>

task ExecWorksCode0 {
	$script:ExecWorksCode0 = exec { cmd /c echo Code0 }
}

task ExecWorksCode42 {
	$script:ExecWorksCode42 = exec { PowerShell "'Code42'; exit 42" } { $LastExitCode -eq 42 }
	assert ($LastExitCode -eq 42)
}

task default ExecWorksCode0, ExecWorksCode42, {
	assert ($script:ExecWorksCode0 -eq 'Code0')
	assert ($script:ExecWorksCode42 -eq 'Code42')
}

task ExecFailsCode13 {
	exec { PowerShell "exit 13" }
}

task ExecFailsBadCommand {
	exec { throw 'Bad Command.' }
}

task ExecFailsBadValidate {
	exec { cmd /c echo hi } { throw 'Bad Validate.' }
}
