
param(
	# Using an extra prefix does not change existing prefixes.
	[ValidateScript({"test::..\Test.build.ps1"})]
	$Extends
)

# References base tasks using prefixes.
task Build my::Task, one::Required, two::Required, test::Build

# Redefined dot-task.
task . Build
