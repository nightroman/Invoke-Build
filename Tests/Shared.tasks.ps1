
<#
.Synopsis
	Example of a script with imported tasks (like MSBuild .targets file).

.Description
	See .build.ps1, the line with Shared.tasks.ps1 and comments.
#>

# Just writes a string
task SharedTask1 {
	'In SharedTask1'
}

# Depends on SharedTask1 and writes another string
task SharedTask2 SharedTask1, {
	'In SharedTask2'
}
