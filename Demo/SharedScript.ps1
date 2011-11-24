
<#
.Synopsis
	Functions shared between build scripts.
#>

<#
.Synopsis
	Formats error information.

.Description
	It replaces formatting by Out-String which does not work in strict mode
	with some hosts due to internal errors like "property not found".
#>
function Format-Error($$) {
	@"
$$
$($$.InvocationInfo.PositionMessage.Trim().Replace("`n", "`r`n"))
+ $($$.CategoryInfo)
"@
}

<#
.Synopsis
	Invokes a build with an issue and comparer the error with a pattern.
#>
function Test-Issue([Parameter()]$Task, $File, $ExpectedPattern) {
	$message = ''
	try { Invoke-Build $Task $File }
	catch { $message = Format-Error $_ }
	Write-BuildText Magenta $message
	if ($message -notlike $ExpectedPattern) {
		Write-Error -ErrorAction Stop @"
Expected pattern [
$ExpectedPattern
]
Actual error [
$message
]
"@
	}
}
