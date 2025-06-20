
param(
	[ValidateScript({"B2::B2.build.ps1"})]
	$Extends
)

task main meta, B2::build2

task . main
