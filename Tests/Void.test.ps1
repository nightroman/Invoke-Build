
<#
.Synopsis
	Shows how to replace all tasks with a void, depending on a condition.

.Description
	This scenario is typical on testing when a script contains tests designed
	to be invoked only on some condition, e.g. PowerShell v42.0+ like in here.

	Any build script must have at least one task. This rule is for preventing
	calls of non build scripts by mistake. Thus, we cannot just check for a
	condition and return. A dummy task should be added.
#>

# Check version, add a void task, and return (same as {task NoTasksForV42; return})
if ($PSVersionTable.PSVersion.Major -lt 42) {return task NoTasksForV42}

# This task is not going to be invoked on Invoke-Build **
task DesignedForV42 {
	# proof
	throw 42
}
