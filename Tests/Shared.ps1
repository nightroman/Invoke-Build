<#
.Synopsis
	Functions shared between build scripts.
#>

$IsUnix = $PSVersionTable['Platform'] -eq 'Unix'
$Separator = if ($IsUnix) {'/'} else {'\'}

function Replace-NL($text) {
	$text.Replace("`r`n", "`n")
}

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

# Tests and outputs MSBuild.exe path.
# $Path: full path or an alias.
function Test-MSBuild([Parameter()]$Path) {
	if ($Path -is [System.Management.Automation.AliasInfo]) {
		$Path = $Path.Definition
	}
	if ($Path -notlike '*\MSBuild.exe') {Write-Error "Unexpected path $Path"}
	if (![System.IO.File]::Exists($Path)) {Write-Error "Missing file $Path"}
	$Path
}

# Simple mock helper. Must be dot-sourced.
# Arguments:
# [0]: Command name
# [1]: Script block
function Set-Mock {
	if ($MyInvocation.InvocationName -ne '.') {Write-Error -ErrorAction 1 'Dot-source Set-Mock.'}
	Set-Alias $args[0] "Mock-$($args[0])"
	Set-Content "function:\Mock-$($args[0])" $args[1]
}
