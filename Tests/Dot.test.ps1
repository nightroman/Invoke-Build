
<#
.Synopsis
	Tests dot-sourcing of Invoke-Build.

.Description
	Dot-sourcing of Invoke-Build is used not only for getting build commands
	help. It can be used in normal scripts in order to import the task-like
	environment and tools.

.Example
	Invoke-Build * Dot.test.ps1
#>

# Synopsis: Invokes Dot-test.ps1
task Dot-test.ps1 {
	if ($PSVersionTable.PSVersion.Major -eq 2) {
		exec {PowerShell -Version 2 -NoProfile .\Dot-test.ps1}
	}
	else {
		exec {PowerShell -NoProfile .\Dot-test.ps1}
	}
}
