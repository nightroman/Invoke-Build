
<#
.Synopsis
	Tests of Get-BuildProperty (property).

.Description
	This script should be called with no parameters.

.Example
	Invoke-Build * Property.test.ps1
#>

param
(
	$Param1 = (property BuildFile),
	$Param2 = (property UserName)
)

. .\Shared.ps1

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

# Error: missing property
task MissingProperty {
	property _111126_181750
}

# Test error cases.
task . (job MissingProperty -Safe), {
	Test-Error MissingProperty "Missing variable '_111126_181750'.*At *\Property.test.ps1:*ObjectNotFound*"
}
