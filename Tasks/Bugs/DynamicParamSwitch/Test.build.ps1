param(
	[switch]$Extra
)

task clean {
	# for testing
	$global:task_clean = [bool]$Extra
}

task build {
	# for testing
	$global:task_build = [bool]$Extra
}
