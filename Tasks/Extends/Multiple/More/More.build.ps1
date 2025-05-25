
param(
	$More1,
	$More2 = 'more2'
)

#
# Tasks
#

task MoreTask1 {
	"MoreTask1 More1=$More1 More2=$More2"
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
