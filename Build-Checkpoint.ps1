<#
Copyright (c) Roman Kuzmin

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
#>

#.ExternalHelp Help.xml
[CmdletBinding(DefaultParameterSetName='Default')]
param(
	[Parameter(Position=0, Mandatory=1)]
	[string]$Checkpoint
	,
	[Parameter(Position=1)]
	[hashtable]$Build
	,
	[switch]$Preserve
	,
	[Parameter(ParameterSetName='Resume', Mandatory=1)]
	[switch]$Resume
	,
	[Parameter(ParameterSetName='Auto', Mandatory=1)]
	[switch]$Auto
)

$ErrorActionPreference = 1
try {

$Checkpoint = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Checkpoint)

$Build = if ($Build) {@{} + $Build} else {@{}}
if ($Build['WhatIf']) {throw 'WhatIf is not supported.'}

${*checkpoint} = @{
	Checkpoint = $Checkpoint
	Preserve = $Preserve
	Result = $Build['Result']
	Data = $null
}
$Build.Remove('Result')

$Auto = $PSCmdlet.ParameterSetName -eq 'Auto' -and $Auto
$Resume = $PSCmdlet.ParameterSetName -eq 'Resume' -and $Resume

if ($Auto) {
	$Resume = [System.IO.File]::Exists($Checkpoint)
}

if ($Resume) {
	if (![System.IO.File]::Exists($Checkpoint)) {throw "Missing checkpoint '$Checkpoint'."}
	${*checkpoint}.Data = try {Import-Clixml $Checkpoint} catch {throw 'Invalid checkpoint file?'}

	foreach($_ in @($Build.get_Keys())) {
		if ($_ -ne 'Safe' -and $_ -ne 'Summary') {
			$Build.Remove($_)
		}
	}
	$Build.Task = ${*checkpoint}.Data.Task
	$Build.File = ${*checkpoint}.Data.File
	$Build = $Build + ${*checkpoint}.Data.Prm1
}

${*checkpoint}.XBuild = {
	if (${*checkpoint}.Data) {
		foreach($_ in ${*checkpoint}.Data.Done) {
			${*}.All[$_].Elapsed = [TimeSpan]::Zero
		}
		foreach($_ in ${*checkpoint}.Data.Prm2.GetEnumerator()) {
			Set-Variable $_.Key $_.Value -Scope Script
		}
		if ($_ = ${*}.Data['Checkpoint.Import']) {
			. *Run $_ ${*checkpoint}.Data.User
		}
	}
}

${*checkpoint}.XCheck = {
	Export-Clixml ${*checkpoint}.Checkpoint -InputObject @{
		User = *Run ${*}.Data['Checkpoint.Export']
		Task = $BuildTask
		File = $BuildFile
		Prm1 = $(
			$r = @{}
			foreach($_ in ${*}.DP.get_Values()) {
				if ($_.IsSet) {
					$r[$_.Name] = $_.Value
				}
			}
			$r
		)
		Prm2 = $(
			$r = @{}
			foreach($_ in ${*}.DP.get_Keys()) {
				$r[$_] = Get-Variable -Name $_ -Scope Script -ValueOnly
			}
			$r
		)
		Done = @(
			foreach($t in ${*}.All.get_Values()) {
				if ($t.Elapsed -and !$t.Error) {
					$t.Name
				}
			}
		)
	}
}

$_ = $Build
Remove-Variable Checkpoint, Build, Preserve, Resume, Auto

Set-Alias Invoke-Build (Join-Path (Split-Path $MyInvocation.MyCommand.Path) Invoke-Build.ps1)
Invoke-Build @_ -Result ${*checkpoint}

if (!${*checkpoint}.Value.Error -and !${*checkpoint}.Preserve) {
	[System.IO.File]::Delete(${*checkpoint}.Checkpoint)
}
}
catch {
	if ($_.InvocationInfo.ScriptName -notmatch '\b(Invoke-Build|Build-Checkpoint)\.ps1$') {throw}
	$PSCmdlet.ThrowTerminatingError($_)
}
finally {
	if ($r = ${*checkpoint}.Result) {
		if ($r -is [string]) {
			New-Variable $r ${*checkpoint}.Value -Scope 1 -Force
		}
		else {
			$r.Value = ${*checkpoint}.Value
		}
	}
}
