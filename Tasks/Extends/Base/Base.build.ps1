
param(
	$Base1,
	$Base2 = 'base2'
)

#
# Tasks
#

task BaseTask1 {
	"BaseTask1 Base1=$Base1 Base2=$Base2"
}

task . BaseTask1

#
# Blocks
#

Enter-Build {
	"Base Enter-Build BuildRoot=$BuildRoot"
}

Exit-Build {
	"Base Exit-Build BuildRoot=$BuildRoot"
}

Enter-BuildTask {
	"Base Enter-BuildTask Task=$($Task.Name)"
}

Exit-BuildTask {
	"Base Exit-BuildTask Task=$($Task.Name)"
}

Enter-BuildJob {
	"Base Enter-BuildJob Task=$($Task.Name)"
}

Exit-BuildJob {
	"Base Exit-BuildJob Task=$($Task.Name)"
}
