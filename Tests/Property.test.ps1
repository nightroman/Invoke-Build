
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

equals $Param1 $BuildFile
equals $Param2 $env:USERNAME

equals (property BuildFile) $BuildFile
equals (property UserName) $env:USERNAME

$MissingProperty = property MissingProperty 42
equals $MissingProperty 42

# Null value is treated as missing, too
$MissingNullProperty = $null
$MissingNullProperty = property MissingProperty 42
equals $MissingNullProperty 42

# Error: missing property
task MissingProperty {
	property _111126_181750
}

# Test error cases.
task . (job MissingProperty -Safe), {
	Test-Error MissingProperty "Missing variable '_111126_181750'.*At *\Property.test.ps1:*ObjectNotFound*"
}
