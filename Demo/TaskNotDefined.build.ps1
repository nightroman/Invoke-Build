
<#
.Synopsis
	Example of a missing task call and failure.

.Example
	# This fails because the 'missing' task is missing:
	Invoke-Build . TaskNotFound.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

task task1 missing, {}

task . task1, {}
