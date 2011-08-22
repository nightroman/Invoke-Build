
<#
.Synopsis
	Example of a scripts with imported tasks (like MSBuild *.targets)

.Description
	See .build.ps1, line with .\Shared.tasks.ps1 and comments there.
#>

task SharedTask1 {
	'In SharedTask1'
}

task SharedTask2 SharedTask1, {
	'In SharedTask2'
}
