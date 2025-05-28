<#
.Synopsis
	More build.
.Parameter More1
		Parameter More1.
.Parameter More2
		Parameter More2.
.Parameter MoreX
		Parameter MoreX.
#>

param(
	# Replaced with parameters from "..\..\Base\Base.build.ps1".
	[ValidateScript({"..\..\Base\Base.build.ps1"})]
	$Extends,

	# Own parameters.
	$Configuration = 'Release',
	$More1,
	$More2 = 'more2',
	$MoreX = 'moreX'
)

#
# Tasks
#

# Synopsis: MoreTask1 2025-05-25-1251.
# Parameters: MoreX
# Environment: MoreEnv
task MoreTask1 BaseTask1, {
	"MoreTask1 More1=$More1 More2=$More2"
}

#
# Blocks
#

Enter-Build {
	"More Enter-Build BuildRoot=$BuildRoot - $Configuration"
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
