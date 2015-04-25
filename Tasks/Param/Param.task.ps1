
<#
.Synopsis
	Parametrized task pattern.
#>

# Parameters:
# - The first parameter is the mandatory imported task name.
# - Parameters are used by imported tasks as $Task.Data.
param(
	[Parameter(Mandatory=1)]
	$TaskName,
	$Param1,
	$Param2
)

# Avoid dot-sourcing and pollution of the script scope with these parameters
assert ($MyInvocation.InvocationName -ne '.') 'Do not dot-source this script.'

# Parametrized task definition:
# - Do not use synopsis comment here, put synopsis where it is imported.
# - Attach the parameters by `-Data $PSBoundParameters`.
# - Alter the task source by `-Source $MyInvocation`.
# - Task actions access parameters as `$Task.Data`.
task $TaskName -Data $PSBoundParameters -Source $MyInvocation {
	"
	Param1 = $($Task.Data.Param1)
	Param2 = $($Task.Data.Param2)
	"
}
