
<#
.Synopsis
	Ask-tasks tested by Ask.test.ps1
#>

. ../../Tasks/Ask/Ask.tasks.ps1

### Ask-tasks with conditions

# skipped
ask IfValue0 -If 0 {42}

# invoked
ask IfValue1 -If 1 {42}

# skipped
ask IfScript0 -If {0} {42}

# invoked
ask IfScript1 -If {1} {42}
