
<#
.Synopsis
	psake script converted to Invoke-Build by Convert-psake.ps1

.Description
	This is not a real script, just a set of things to convert.

.Example
	Convert-psake default.ps1 -Invoke -Synopsis
#>

properties {
	$var1 = 'Value1'
	$rootDir  = Resolve-Path .
}

properties {
	$var2 = 'Value2'
}

$taskName = 'Task1'
$var1 = 42

framework "4.0"

framework "4.0x86"

include ".\psake 'ext'.ps1"

function f1($p1, $p2) {
	#...
}

task default -depends Clean, Task1

task Clean -description 'Removes
temp files.' {
	#...
}

task Task1 -alias t1 -continueOnError -requiredVariables x, y {
	#...
}

task Precondition1 -precondition {...} {
	#...
}
task Precondition2 -precondition {...} -depends Task1 {
	#...
}

task Postcondition1 -postcondition {...} {
	#...
}
task Postcondition2 -postcondition {...} -depends $taskName {
	#...
}

TaskSetup {
	#...
}

TaskTearDown {
	#...
}

task All -precondition {...} -postcondition {...} -depends Task1, Clean -preaction {
	# preaction
} -postaction {
	# postaction
} -action {
	# action
}
