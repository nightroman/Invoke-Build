
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
foreach($file in Get-ChildItem MyScript/*.tasks.ps1) {. $file}

### EXAMPLE 2. Import from a module with tasks

# Required variable
$MyModuleParam = 'param1'

# Import the module and dot-source its provided tasks
# In this example we can just call: . MyModule.tasks
# But let's pretend we know just the pattern *.tasks
Import-Module ./MyModule
foreach($file in Get-Command *.tasks -Module MyModule) {. $file}

### MAIN SCRIPT. Define own tasks

# Synopsis: This task calls imported tasks.
task . MyVar, MyEnv, MyProp, MyModuleTask
