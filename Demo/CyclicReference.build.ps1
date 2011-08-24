
<#
.Synopsis
	Tasks with a cyclic reference: . -> task1 -> task2 -> task1 (oops!)

.Example
	# This fails:
	Invoke-Build . CyclicReference.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

task task1 task2
task task2 task1
task . task1
