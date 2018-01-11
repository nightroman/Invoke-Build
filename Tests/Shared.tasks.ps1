
<#
.Synopsis
	Example of a script with imported tasks (like MSBuild .targets file).
#>

param(
	$SleepMilliseconds
)

# Synopsis: Just writes a string.
task SharedTask1 {
	'In SharedTask1'
}

# Synopsis: Calls SharedTask1 and writes another string.
task SharedTask2 SharedTask1, {
	'In SharedTask2'
}

# Synopsis: Simulate time consuming jobs.
task Sleep {
	'begin - начало'
	Start-Sleep -Milliseconds $SleepMilliseconds
	'end - конец'
}
