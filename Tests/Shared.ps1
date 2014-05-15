
<#
.Synopsis
	Functions shared between build scripts.
#>

<#
Formats the error safely. Out-String may not work in strict mode:
https://connect.microsoft.com/PowerShell/feedback/details/708182
#>
function Format-Error($Record)
{
	@"
$Record
$($Record.InvocationInfo.PositionMessage.Trim())
+ $($Record.CategoryInfo)
"@
}

# Invokes the failing build and compares the error with a sample.
function Test-Issue($Task, $File, $Sample)
{
	$message = ''
	try { Invoke-Build $Task $File }
	catch { $message = Format-Error $_ }
	Write-Build Magenta $message
	if ($message -notlike $Sample) {
		Write-Error -ErrorAction Stop "Different errors:`n Sample : $Sample`n Result : $message"
	}
}

# Checks the task for its error and compares it with a sample.
function Test-Error($Task, $Sample)
{
	$e = error $Task
	if (!$e) {Write-Error -ErrorAction Stop "Task '$Task' has not failed."}

	$message = Format-Error $e
	if ($message -notlike $Sample) {
		Write-Error -ErrorAction Stop "Task '$Task': different error:`n Sample : $Sample`n Result : $message"
	}
}
