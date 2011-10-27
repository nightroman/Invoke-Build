
<#
.Synopsis
	Example of imported tasks and data (like MSBuild .targets file).

.Description
	It is not typical but imported task scripts may have script parameters and
	variables, just like build scripts. In this case script should be imported
	by the operator '.' (dot-sourced), so that parameters and variables go to
	the scope of a calling script. Mind potential variable name conflicts in
	the same script scope!

	This script is used by ProtectedTasks.build.ps1 and ErrorCases.build.ps1.
#>

# This task fails (but increments its call counter).
$MyCountError1 = 0
task Error1 {
	++$script:MyCountError1
	"In Error1"
	throw "Error1"
}

# This task is the same as Error1 but uses different names.
$MyCountError2 = 0
task Error2 {
	++$script:MyCountError2
	"In Error2"
	throw "Error2"
}
