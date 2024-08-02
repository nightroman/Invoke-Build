param(
	[Parameter(Mandatory=1)]
	[string]$Case
	,
	[string]$Configuration = 'Release'
)

# Common variables. Case scripts may use them and may override them.
$Var1 = 'root value 1'

# Dot-source the specified case tasks.
$CaseFile = "$Case\$Case.tasks.ps1"
requires -Path $CaseFile
. $CaseFile

# Synopsis: This task is common for all cases.
# It may use assets from the case script.
task root1 {
	"case : $CaseRoot" # expected to be defined by cases
	"var1 : $Var1"     # defined by root, may be changed by cases (case2)
}
