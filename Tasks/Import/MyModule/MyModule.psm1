
# Define some usual module stuff, e.g. an exported function.
function Invoke-MyModuleStuff($Param) {
	"@Invoke-MyModuleStuff $Param"
}

# Provide an alias with a full path to the task script.
Set-Alias MyModule.tasks $PSScriptRoot/MyModule.tasks.ps1

# Export the usual module stuff and the alias for tasks.
Export-ModuleMember -Function Invoke-MyModuleStuff -Alias MyModule.tasks
