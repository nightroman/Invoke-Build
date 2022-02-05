<#
.Synopsis
	Tests dot-sourcing of Invoke-Build.

.Description
	Dot-sourcing of Invoke-Build is used not only for getting build commands
	help. It can be used in normal scripts in order to import the task-like
	environment and tools.
#>

# Synopsis: Invokes Dot-test.ps1
task Dot-test {
	exec {Invoke-PowerShell -NoProfile ./Dot-test.ps1}
}
