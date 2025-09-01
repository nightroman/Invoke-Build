<#
.Synopsis
	Example of tasks and job lists created dynamically.

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

# Yet another task. As it is called by parallel tests, let's use some Write-*
# methods. They may have issues in some hosts. Also, let's use some not ASCII.
task task0 {
	print Cyan 'Cyan - Циан'
	Write-Verbose 'Verbose - Подробно' -Verbose
}

# Join "static" and "dynamic" jobs together.
task . $('task0'; $jobs)
