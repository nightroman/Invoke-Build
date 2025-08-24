
param(
	[ValidateScript({"B1.build.ps1"})]
	$Extends
)

task build2 build, test2

task test2 test, {
	'Do more tests.'
}

# v5.14.17
task test3
task after -After test3
task before -Before test3
