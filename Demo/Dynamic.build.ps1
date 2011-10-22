
<#
.Synopsis
	Example of tasks created dynamically.

.Example
	Invoke-Build . Dynamic.build.ps1
#>

# Add a task for each item and collect names to be used as jobs.
$jobs = foreach($_ in 1..3) {
	task "task$_" ([scriptblock]::Create("'task$_'"))
	"task$_"
}

# Yet another task.
task task0 {}

# Call "static" and "dynamic" tasks.
task . task0, $jobs
