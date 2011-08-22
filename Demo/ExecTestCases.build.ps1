
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
	if ($LastExitCode -ne 42) { throw }
}

task default ExecWorksCode0, ExecWorksCode42, {
	if ($script:ExecWorksCode0 -ne 'Code0') { throw }
	if ($script:ExecWorksCode42 -ne 'Code42') { throw }
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
