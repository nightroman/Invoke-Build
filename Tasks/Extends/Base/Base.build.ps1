<#
.Synopsis
	Base build.
.Parameter Base1
		Parameter Base1.
.Parameter Base2
		Parameter Base2.
#>

param(
	$Configuration = 'Debug',
	$Base1,
	$Base2 = 'base2'
)

#
# Tasks
#

# Synopsis: BaseTask1.
# Parameters: Base1, Base2
# Environment: BaseEnv
task BaseTask1 {
	"BaseTask1 Base1=$Base1 Base2=$Base2"
}

# Synopsis: Base dot-task.
task . BaseTask1

#
# Blocks
#

Enter-Build {
	"Base Enter-Build BuildRoot=$BuildRoot - $Configuration"
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
