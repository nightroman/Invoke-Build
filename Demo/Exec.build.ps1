
<#
.Synopsis
	Examples and test cases of Invoke-Exec (exec).

.Example
	Invoke-Build . Exec.build.ps1
#>

. .\Shared.ps1

task ExecWorksCode0 {
	$script:ExecWorksCode0 = exec { cmd /c echo Code0 }
}

task ExecWorksCode42 {
	$script:ExecWorksCode42 = exec { cmd /c 'echo Code42&& exit 42' } (40..50)
	assert ($LastExitCode -eq 42)
}

task ExecFailsCode13 {
	exec { cmd /c exit 13 }
}

task ExecFailsBadCommand {
	exec { throw 'throw in ExecFailsBadCommand' }
}

# The default task calls the others and tests results.
# Note use of @{} for failing tasks.
task . `
ExecWorksCode0,
ExecWorksCode42,
@{ExecFailsCode13=1},
@{ExecFailsBadCommand=1},
{
	assert ($script:ExecWorksCode0 -eq 'Code0')
	assert ($script:ExecWorksCode42 -eq 'Code42')
	Test-Error ExecFailsCode13 'The command { cmd /c exit 13 } exited with code 13.*At *\Exec.build.ps1:*{ cmd /c exit 13 }*'
	Test-Error ExecFailsBadCommand "throw in ExecFailsBadCommand*At *\Exec.build.ps1:*'throw in ExecFailsBadCommand'*"
}
