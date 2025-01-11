<#
.Synopsis
	Directly invocable script with build tasks (variant 2).
#>

[CmdletBinding()]
param(
	# Choose the default: '*' ~ run all; '?' - show tasks; '.' or nothing ~ default task.
	[string[]]$Tasks = '*'
	,
	# Other parameters as usual.
	[string]$Param1 = 'Value1'
)

# Outer script scope, suitable for common functions and variables for reading.

# This function is available for tasks.
function Get-CommonSomething {
	'CommonSomething'
}

# This variable is available for reading as $Var1 and not "easily" available for writing.
$Var1 = 10

# Call the engine with the script block adding tasks.
Invoke-Build $Tasks {
	# Inner script scope, this is the usual build script body with tasks, variables, functions.

	# This variable is available for reading as $Var1 or $Script:Var2 and for writing as $Script:Var2
	$Var2 = 20

	# Synopsis: $ErrorActionPreference is set to 1, equivalent "Stop" or [System.Management.Automation.ActionPreference]::Stop.
	task ErrorActionPreferenceIsStop {
		equals $ErrorActionPreference 1
	}

	# Synopsis: The build folder is this script folder regardless of the location where this script is invoked from.
	task BuildRootIsThisScriptRoot {
		equals $BuildRoot $PSScriptRoot
		equals "$PWD" $PSScriptRoot
	}

	# Synopsis: Script functions are available for tasks.
	task ScriptFunctions {
		Get-CommonSomething
	}

	# Synopsis: Script parameters.
	task ScriptParameters {
		"Tasks = $Tasks"
		"Param1 = $Param1"
	}

	# Synopsis: Script variables.
	task ScriptVariables {
		"Var1 = $Var1"
		"Var2 = $Var2"
		++$Script:Var2
		"Var2 = $Var2"
	}
}
