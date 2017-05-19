
<#
.Synopsis
	Parametrized task pattern.
#>

# DSL
Set-Alias MyTask Add-MyTask

# Adds a custom task. Parameters are standard task parameter (needed for this
# particular custom task, at least `Name`) and other parameters to be used as
# `$Task.Data` in task code.
function Add-MyTask
(
	[Parameter(Mandatory=1)]
	$Name,
	$Param1,
	$Param2
)
{
	# Parametrized task definition:
	# - Do not use synopsis comment here, put synopsis where it is imported.
	# - Attach the parameters by `-Data $PSBoundParameters`.
	# - Alter the task source by `-Source $MyInvocation`.
	# - Task actions access parameters as `$Task.Data`.
	task $Name -Data $PSBoundParameters -Source $MyInvocation {
		"
		Param1 = $($Task.Data.Param1)
		Param2 = $($Task.Data.Param2)
		"
	}
}
