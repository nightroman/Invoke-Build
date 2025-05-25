
param(
	# Replaced with parameters from "..\..\Base\Base.build.ps1".
	[ValidateScript({"..\..\Base\Base.build.ps1"})]
	$Extends,

	# Own parameters.
	$More1,
	$More2 = 'more2'
)

# Own task.
task MoreTask1 BaseTask1, {
	"MoreTask1 Base1=$Base1 Base2=$Base2 More1=$More1 More2=$More2"
}

#
# Blocks
#

Enter-Build {
	"More Enter-Build BuildRoot=$BuildRoot"
}

Exit-Build {
	"More Exit-Build BuildRoot=$BuildRoot"
}

Enter-BuildTask {
	"More Enter-BuildTask Task=$($Task.Name)"
}

Exit-BuildTask {
	"More Exit-BuildTask Task=$($Task.Name)"
}

Enter-BuildJob {
	"More Enter-BuildJob Task=$($Task.Name)"
}

Exit-BuildJob {
	"More Exit-BuildJob Task=$($Task.Name)"
}
