
param(
	# Replaced with parameters from "More.build.ps1" (and "Base.build.ps1", recursively).
	[ValidateScript({"More\More.build.ps1"})]
	$Extends,

	# Own parameters.
	$Test1,
	$Test2 = 'test2'
)

# Own task.
task TestTask1 MoreTask1, {
	"TestTask1 Base1=$Base1 Base2=$Base2 More1=$More1 More2=$More2 Test1=$Test1 Test2=$Test2"
}

# Redefine dot.
task . TestTask1
