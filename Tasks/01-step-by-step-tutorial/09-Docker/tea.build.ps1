<#
New features:
	- new file `implicit.Dockerfile` does not install InvokeBuild
	- new file `explicit.Dockerfile` gets and imports InvokeBuild
	- new parameter `Docker` to choose 'implicit', 'explicit'
	- new task `docker` to build the image
	- PowerShell script help comments

Build the Docker image, then run it:
	Invoke-Build docker
	Invoke-Build docker -Docker explicit

	docker run tea

See -WhatIf info and script help:
	Invoke-Build -WhatIf
	help ./tea.build.ps1
#>

<#
.Synopsis
	The step-by-step-tutorial final script.

.Parameter Tasks
		Specifies the tasks to run. Used on direct calls by PowerShell.

.Parameter TeaBags
		Tells how many tea bags to add. Used by `add_tea`.

.Parameter SugarLumps
		Tells how many sugar lumps to add. Used by `add_sugar`.

.Parameter Docker
		Tells how to build the Docker image. Used by `docker`. Values: implicit (default), explicit
#>
param(
	[Parameter(Position=0)]
	[string[]]$Tasks
	,
	[int]$TeaBags = 1
	,
	[int]$SugarLumps
	,
	[ValidateSet('implicit', 'explicit')]
	[string]$Docker = 'implicit'
)

# bootstrap
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
	$ErrorActionPreference = 1
	if (!(Get-Command Invoke-Build -ErrorAction 0)) {
		Write-Host 'Installing module InvokeBuild...'
		Install-Module InvokeBuild -Scope CurrentUser -Force
		Import-Module InvokeBuild
	}
	return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

Exit-Build {
	$Script:Pot
}

# Synopsis: Builds Docker image `tea`.
task docker {
	exec { docker build -t tea -f "$Docker.Dockerfile" . }
}

# Synopsis: Boils a pot of water.
task boil_water {
	'boiling water'
	$Script:Pot = @{}
}

# Synopsis: Adds tea bags.
task add_tea boil_water, {
	'adding tea'
	$Script:Pot.tea = $TeaBags
}

# Synopsis: Adds sugar lumps.
task add_sugar -If { $SugarLumps -ge 1 } -Jobs boil_water, {
	'adding sugar'
	$Script:Pot.sugar = $SugarLumps
}

task . boil_water, add_tea, add_sugar
