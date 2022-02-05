<#
.Synopsis
	Exposed aliases, functions, variables.
#>

if ($PSVersionTable.PSVersion.Major -lt 5) {return task forV5x}
Import-Module .\Tools

# Synopsis: Invoke-Build should expose only documented aliases.
task ExposedAliases {
	$exposed = [PowerShell]::Create().AddScript({
		$ErrorActionPreference=1
		$_after = [System.Collections.Generic.List[object]]@()
		$_before = Get-Command -CommandType Alias | Select-Object -ExpandProperty Name
		$null = Invoke-Build . {
			task . {
				$_after.AddRange((Get-Command -CommandType Alias | Select-Object -ExpandProperty Name))
			}
		}
		foreach($name in $_after) { if ($_before -notcontains $name) {
			$name
		}}
	}).Invoke()

	$known = @'
assert
Build-Parallel
equals
error
exec
Invoke-Build
property
remove
requires
Resolve-MSBuild
Show-TaskHelp
task
use
'@ -split '\r?\n'

	$exposed
	Assert-Compare $known $exposed
}

# Synopsis: Invoke-Build should expose only documented functions.
task ExposedFunctions {
	$exposed = [PowerShell]::Create().AddScript({
		$ErrorActionPreference=1
		function Get-FunctionAndFilter {
			$(
				Get-Command -CommandType Function
				Get-Command -CommandType Filter
			) |
			Select-Object -ExpandProperty Name |
			Sort-Object
		}
		$_after = [System.Collections.Generic.List[object]]@()
		$_before = Get-FunctionAndFilter
		$null = Invoke-Build . {
			task . {
				$_after.AddRange((Get-FunctionAndFilter))
			}
		}
		foreach($name in $_after) { if ($_before -notcontains $name) {
			$name
		}}
	}).Invoke()

	$known = @'
*Amend
*At
*Check
*Die
*Echo
*Err
*Fin
*Help
*IO
*Job
*Msg
*My
*Path
*Root
*Run
*SL
*Task
*Unsafe
*Write
Add-BuildTask
Assert-Build
Assert-BuildEquals
Confirm-Build
Enter-Build
Enter-BuildJob
Enter-BuildTask
Exit-Build
Exit-BuildJob
Exit-BuildTask
Get-BuildError
Get-BuildFile
Get-BuildProperty
Get-BuildSynopsis
Invoke-BuildExec
Remove-BuildItem
Set-BuildData
Set-BuildFooter
Set-BuildHeader
Test-BuildAsset
Use-BuildAlias
Write-Build
Write-Warning
'@ -split '\r?\n'

	$exposed
	Assert-Compare $known $exposed
}

# Synopsis: Invoke-Build should expose only documented variables.
task ExposedVariables {
	$exposed = [PowerShell]::Create().AddScript({
		$ErrorActionPreference=1
		$_after = [System.Collections.Generic.List[object]]@()
		$_before = ''
		$_before = Get-Variable | Select-Object -ExpandProperty Name
		$null = Invoke-Build . {
			task . {
				$_after.AddRange((Get-Variable | Select-Object -ExpandProperty Name))
			}
		}
		#! exclude `_`, it is sorted differently with `*` in v5 and v7
		foreach($name in $_after) { if ($_before -notcontains $name -and $name -ne '_') {
			$name
		}}
	}).Invoke()

	$known = @'
*
BuildFile
BuildRoot
BuildTask
foreach
Job
OriginalLocation
PSCmdlet
PSItem
Task
WhatIf
'@ -split '\r?\n'

	$exposed
	Assert-Compare $known $exposed
}
