<#
.Synopsis
	More build.
.Parameter More1
		Parameter More1.
.Parameter More2
		Parameter More2.
#>

param(
	$Configuration = 'Release',
	$More1,
	$More2 = 'more2'
)

#
# Tasks
#

# Synopsis: MoreTask1.
# Parameters: More1, More2
# Environment: MoreEnv
task MoreTask1 {
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
