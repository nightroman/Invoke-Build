
<#
.Synopsis
	Example of tasks created dynamically.

.Notes
	It is used in parallel and job build tests.

.Example
	Invoke-Build . Dynamic.build.ps1
#>

# Add a task for each item and collect names to be used as jobs.
$jobs = foreach($_ in 1..3) {
	task "task$_" ([scriptblock]::Create("'task$_'"))
	"task$_"
}

# Yet another task. As far as it is called by parallel and job tests, it uses
# Write-Host and Write-BuildText. This methods have issues in some hosts. Also,
# let's use some not ASCII text.
task task0 {
	Write-Host 'Host - Хост'
	Write-BuildText Cyan 'Cyan - Циан'
}

# Call "static" and "dynamic" tasks.
task . task0, $jobs
