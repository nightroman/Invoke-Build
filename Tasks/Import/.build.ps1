
<#
.Synopsis
	Example of imported tasks with `requires`.

.Description
	This example build script does not have its own tasks. All tasks are
	imported by dot-sourcing some "conventional" task files. In practice,
	build scripts have own tasks and import some extras in addition.

	Before importing, the script defines variables required by imported
	scripts. If you remove any of them then the import fails due to the
	`requires` commands in the imported scripts.

.Example
	> Invoke-Build ?
	Show tasks. In this sample they are all imported.
#>

# Required session variable for 1.tasks.ps1
$MyVar1 = 'var1'

# Required environment variable for 2.tasks.ps1
$env:MyEnv1 = 'env1'

# Required session or environment variables for 3.tasks.ps1
$MyProp1 = 'prop1'
$env:MyProp2 = 'prop2'

# Import tasks by dot-sourcing all available task scripts
foreach($_ in Get-ChildItem *.tasks.ps1) {. $_}
