
<#
.Synopsis
	Tasks with a cyclic reference: default -> task1 -> task2 -> task1

.Example
	# This fails:
	Invoke-Build default CyclicReference.build.ps1

.Link
	.build.ps1
#>

task task1 task2
task task2 task1
task default task1
