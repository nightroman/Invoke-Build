
<#
.Synopsis
	Example of a build script with conflicting task names.

.Example
	# This fails:
	Invoke-Build . TaskAddedTwice.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

task task1 {}
task task1 {}
