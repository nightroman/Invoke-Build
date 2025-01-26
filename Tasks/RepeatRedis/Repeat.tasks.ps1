<#
.Synopsis
	Defines repeat-task parameters `repeat` using Redis.

.Description
	Build scripts dot-source this script in order to use `repeat`.
	Repeat-tasks are invoked periodically with specified periods.

	Normal task parameters:
		- Name, Inputs, Outputs, Partial

	Custom repeat parameters:
		- Span -- task period
		- Jobs -- task jobs
		- If -- task condition

	Script scope names:
		Alias: repeat -- makes repeat-tasks parameters
		Variables: $db -- Redis database, used internally but may be used by tasks as well
		Functions: New-Repeat, Test-Repeat, Complete-Repeat -- used internally

.Parameter RedisTaskPrefix
		Specifies Redis prefix for task strings.

.Parameter RedisConfiguration
		Optional Redis configuration string.
		Default: $env:FARNET_REDIS_CONFIGURATION
#>

param(
	[Parameter(Mandatory=1)]
	[string]$RedisTaskPrefix
	,
	[string]$RedisConfiguration
)

if (!$WhatIf) {
	Import-Module FarNet.Redis
	$db = Open-Redis -Configuration $RedisConfiguration
}

# "DSL" for scripts.
Set-Alias repeat New-Repeat

# Creates repeat-task parameters.
function New-Repeat(
	[Parameter(Position=0, Mandatory=1)]
	[timespan]$Span
	,
	[Parameter(Position=1)]
	[object[]]$Jobs
	,
	[object]$If=$true
)
{
	@{
		Jobs = $Jobs
		If = {Test-Repeat}
		Done = {Complete-Repeat}
		Data = @{If = $If; Span = $Span}
	}
}

# Works as tasks `If`. The original condition is processed first. If it is true
# then the Redis task key is tested. If it exists then the task is skipped.
function Test-Repeat {
	$_ = $Task.Data.If
	if ($_ -is [scriptblock]) {
		$_ = & $_
	}

	if ($_) {
		!(Get-RedisKey ($RedisTaskPrefix + $Task.Name) -TimeToLive)
	}
}

# Works as tasks `Done`, on success sets Redis task string and time to live.
function Complete-Repeat {
	$key = $RedisTaskPrefix + $Task.Name
	$now = [datetime]::Now.ToString('s')
	if (!$Task.Error) {
		Set-RedisString $key $now -TimeToLive $Task.Data.Span
	}
}
