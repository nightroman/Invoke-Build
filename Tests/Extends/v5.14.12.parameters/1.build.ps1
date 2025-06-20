
param(
	[ValidateScript({"B1::B1.build.ps1", "B2::B2.build.ps1"})]
	$Extends,
	$Platform = (property Platform x64)
)

task test1 B1::test1, B2::test1

task . test1
