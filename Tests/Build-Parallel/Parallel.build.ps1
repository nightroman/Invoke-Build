<#
.Synopsis
	Tasks for Parallel.test.ps1.
#>

param(
	$SleepMilliseconds
)

# Simulate time consuming job with the specified time.
# Also use non-ascii output to cover fixed issues.
task Sleep {
	'begin - начало'
	Start-Sleep -Milliseconds $SleepMilliseconds
	'end - конец'
}
