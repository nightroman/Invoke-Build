
<#
.Synopsis
	Tests of Get-BuildProperty (property).

.Description
	This script should be called with no parameters.

.Example
	Invoke-Build . Property.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

param
(
	$Param1 = (property BuildFile),
	$Param2 = (property UserName)
)

assert ($Param1 -eq $BuildFile)
assert ($Param2 -eq $env:USERNAME)

assert ((property BuildFile) -eq $BuildFile)
assert ((property UserName) -eq $env:USERNAME)

$MissingProperty = property MissingProperty 42
assert ($MissingProperty -eq 42)

# Tests are done but at least one task is needed anyway.
task .
