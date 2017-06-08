
<#
.Synopsis
	Example of imported tasks and `requires`.

.Description
	See README.

.Example
	> Invoke-Build ?
	Show tasks. In this sample most of them are imported.
#>

### EXAMPLE 1. Import from conventional task scripts

# Define required
# - session variable for 1.tasks.ps1
# - environment variable for 2.tasks.ps1
# - session or environment variables for 3.tasks.ps1
$MyVar1 = 'var1'
$env:MyEnv1 = 'env1'
$MyProp1 = 'prop1'
$env:MyProp2 = 'prop2'

# Import tasks by dot-sourcing available task scripts
foreach($_ in Get-ChildItem MyScript/*.tasks.ps1) {. $_}

### EXAMPLE 2. Import from a module with tasks

# Required variable
$MyModuleParam = 'param1'

# Import the module and dot-source its tasks
Import-Module ./MyModule
. MyModule.tasks

### MAIN SCRIPT. Define own tasks

# Synopsis: This task calls imported tasks.
task . MyVar, MyEnv, MyProp, MyModuleTask
