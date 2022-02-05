<#
.Synopsis
	How to replace all tasks with a void, depending on a condition.

.Description
	This scenario is typical on testing when a script contains tests designed
	for some common condition, e.g. PowerShell v42.0+ here.

	Build script must have at least one task. This rule is for preventing calls
	of non build scripts by mistake. Thus, we cannot just check for a condition
	and return. A dummy task should be added.
#>

# Check version, add a void task, and return
if ($PSVersionTable.PSVersion.Major -lt 42) {return task NoTasksForV42}

# This task is not invoked on Invoke-Build *
task DesignedForV42 {
	throw 42
}
