# Common test tools.

#! Write-Error stops
$ErrorActionPreference=1

<#
.Synopsis
	Calls Compare-Object and fails on differences.
.Description
	The error message explains the differences.
#>
function Assert-Compare([object]$A, [object]$B) {
	$diff = Compare-Object $A $B -CaseSensitive -SyncWindow 0
	if ($diff) {
		Write-Error ($diff | Out-String).TrimEnd()
	}
}

<#
.Synopsis
	Gets the platform directory separator char.
#>
function Get-Separator {
	[System.IO.Path]::DirectorySeparatorChar
}

<#
.Synopsis
	Formats the error safely. Out-String may fail in strict mode.
#>
function Format-Error([System.Management.Automation.ErrorRecord]$Record) {
	"$Record`n$($Record.InvocationInfo.PositionMessage.Trim())`n+ $($Record.CategoryInfo)"
}

<#
.Synopsis
	Replaces CRLF with LF.
#>
function Format-LF([string]$Text) {
	$Text.Replace("`r`n", "`n")
}

<#
.Synopsis
	Removes ANSI escape sequences from string(s).
#>
function Remove-Ansi([object]$Text) {
	$Text -replace "`e\[\d+m"
}

<#
.Synopsis
	Compares the error with the wildcard.
#>
function Test-Error([System.Management.Automation.ErrorRecord]$Record, [string]$Like) {
	if (!$Record) {
		Write-Error 'Expected error record.'
	}

	$_ = Format-Error $Record

	if ($_ -notlike $Like) {
		Write-Error "Different error:`n Sample : $Like`n Result : $_"
	}
}

<#
.Synopsis
	Tests and outputs MSBuild.exe path. $Path: the path or alias.
#>
function Test-MSBuild([object]$Path) {
	if ($Path -is [System.Management.Automation.AliasInfo]) {
		$Path = $Path.Definition
	}

	if ($Path -notlike '*\MSBuild.exe') {
		Write-Error "Unexpected path $Path"
	}

	if (![System.IO.File]::Exists($Path)) {
		Write-Error "Missing file $Path"
	}

	$Path
}

<#
.Synopsis
	Gets true if the platform is Unix.
#>
function Test-Unix {
	$PSVersionTable['Platform'] -eq 'Unix'
}
