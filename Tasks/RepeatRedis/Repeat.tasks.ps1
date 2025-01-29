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
		Alias:
			repeat
			-- Makes repeat parameters, designed for tasks.
		Functions:
			Write-TaskLog, New-Repeat, Test-Repeat, Complete-Repeat
			-- Write-TaskLog may be used by tasks, others are internal.
		Variables:
			$db
			-- Redis database, used internally and may be used by tasks.
			(FarNet.Redis cmdlets will use this variable automatically)

.Parameter RedisTaskPrefix
		Specifies Redis prefix for task keys.

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

# Adds a message to the task log (Redis list).
function Write-TaskLog(
	[Parameter(Position=0, Mandatory=1)]
	[string]$Message
)
{
	Set-RedisList ($RedisTaskPrefix + $Task.Name) -RightPush $Message
}

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
		If = ${function:Test-Repeat}
		Done = ${function:Complete-Repeat}
		Data = @{If = $If; Span = $Span}
	}
}

# Works as tasks `If`. The original condition is processed first. If it is true
# then the Redis task key is tested, the task is skipped with some time to live.
function Test-Repeat {
	$_ = $Task.Data.If
	if ($_ -is [scriptblock]) {
		$_ = & $_
	}

	if ($_) {
		!(Get-RedisKey ($RedisTaskPrefix + $Task.Name) -TimeToLive)
	}
}

# Works as tasks `Done`, logs task completion status and time to Redis, on
# failure logs the error, on success sets time to live to the task period.
function Complete-Repeat {
	$now = [datetime]::UtcNow.ToString('s')
	if ($Task.Error) {
		Write-TaskLog ($Task.Error | Out-String)
		Write-TaskLog "[fail] $now"
	}
	else {
		Write-TaskLog "[done] $now"
		Set-RedisKey ($RedisTaskPrefix + $Task.Name) -TimeToLive $Task.Data.Span
	}
}
