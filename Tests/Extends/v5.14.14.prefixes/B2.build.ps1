
param(
	[ValidateScript({"B1.build.ps1"})]
	$Extends
)

task build2 build, test2

task test2 test, {
	'Do more tests.'
}
