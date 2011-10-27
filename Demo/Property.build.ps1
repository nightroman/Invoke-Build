
<#
.Synopsis
	Tests of Get-BuildProperty (property).

.Description
	This script should be called with no parameters.

.Example
	Invoke-Build . Property.build.ps1
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

# Null value is treated as missing, too
$MissingNullProperty = $null
$MissingNullProperty = property MissingProperty 42
assert ($MissingNullProperty -eq 42)

# All is done but at least one task is needed.
task .
