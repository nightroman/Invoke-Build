
<#
.Synopsis
	Functions shared between build scripts.
#>

<#
.Synopsis
	Formats error information.

.Description
	It replaces formatting by Out-String which does not work in strict mode
	with some hosts due to internal errors:
	https://connect.microsoft.com/PowerShell/feedback/details/708182
#>
function Format-Error($Record)
{
	@"
$Record
$($Record.InvocationInfo.PositionMessage.Trim().Replace("`n", "`r`n"))
+ $($Record.CategoryInfo)
"@
}

<#
.Synopsis
	Invokes a failing build and compares the error with a pattern.
#>
function Test-Issue($Task, $File, $ExpectedPattern)
{
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

<#
.Synopsis
	Checks a task error for an expected pattern.
#>
function Test-Error($Task, $ExpectedPattern)
{
	$e = error $Task
	if (!$e) {Write-Error -ErrorAction Stop "Task '$Task' has not failed."}

	$message = Format-Error $e
	if ($message -notlike $ExpectedPattern) {
		Write-Error -ErrorAction Stop @"
Task '$Task' error:
Expected pattern [
$ExpectedPattern
]
Actual error [
$message
]
"@
	}
}
