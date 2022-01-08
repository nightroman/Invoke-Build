param(
	$Configuration
)

task clean {
	# for testing
	$global:task_clean = $Configuration
}

task build {
	# for testing
	$global:task_build = $Configuration
}
