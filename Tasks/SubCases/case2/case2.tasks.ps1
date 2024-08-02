
# This case overrides the root variable.
$Var1 = 'changed by case2'

# Case assets, may be used by case tasks and root tasks.
$CaseRoot = $PSScriptRoot

# Synopsis: This task is case specific.
# It may use assets from the root script.
task task1 {
	"case file     : $CaseFile"
	"configuration : $Configuration"
	"var1          : $Var1"
}
