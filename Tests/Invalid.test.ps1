<#
.Synopsis
	Tests invalid scripts and tasks.

.Description
	If a build script or a task is invalid then build fails on the first issue.
	In order to test all issues and avoid too many small invalid scripts this
	script creates and tests temporary scripts, one issue each.

.Example
	Invoke-Build * Invalid.test.ps1
#>

. ./Shared.ps1

# Writes a temporary script with an issue, calls it, compares the message.
function Test($ExpectedPattern, $Script, $Task = '.') {
	# write the temp script
	$Script > z.build.ps1

	# invoke
	try { Test-Issue $Task z.build.ps1 $ExpectedPattern }
	catch { Write-Error -ErrorAction Stop $_ }

	# remove the temp script
	Remove-Item z.build.ps1
}

# Build scripts should have at least one task.
task NoTasks {
	# build
	$e = 0
	($r = try {Invoke-Build . {} -Result result} catch {$e = $_})
	$r = Remove-Ansi $r
	Write-Build Magenta ($e | Out-String)

	# caught error
	assert ($e.CategoryInfo.Category -eq 'InvalidData')
	equals $e.FullyQualifiedErrorId Invoke-Build.ps1
	equals $e.InvocationInfo.ScriptName $BuildFile

	# 2.10.4, was 0 errors
	assert ($r -clike "Build ABORTED *${Separator}Invalid.test.ps1. 0 tasks, 1 errors, 0 warnings *")
	equals $result.Errors.Count 1
}

# The task has three valid jobs and one invalid (42 ~ invalid type).
task InvalidJobType {
	Test "Task 'BadTask': Invalid job.*At*BadTask*InvalidArgument*" {
		task task1
		task task2 task1   # [string] - task reference
		task task3 ?task2  # [string] - "?safe" task reference
		task task4 {$x=42} # [scriptblock] - task action block
		task BadTask 42    # other types are invalid
	}
}

# Missing task in jobs.
task TaskNotDefined {
	Test "Task 'task1': Missing task 'missing'.*At *${Separator}z.build.ps1:*InvalidArgument*" {
		task TaskNotDefined task1, {}
		task task1 missing, {}
	}
}

# Missing task in After.
task TaskNotDefinedAfter {
	Test "Task 'AfterMissing': Missing task 'MissingTask'.*At *${Separator}z.build.ps1*InvalidArgument*" {
		task AfterMissing -After MissingTask {}
	}
}

# Missing task in Before.
task TaskNotDefinedBefore {
	Test "Task 'BeforeMissing': Missing task 'MissingTask'.*At *${Separator}z.build.ps1*InvalidArgument*" {
		task BeforeMissing -Before MissingTask {}
	}
}

# Tasks with a cyclic reference: . -> task1 -> task2 -> task1
task CyclicReference {
	Test "Task 'task2': Cyclic reference to 'task1'.*At *${Separator}z.build.ps1:*InvalidArgument*" {
		task CyclicReference task1
		task task1 task2
		task task2 task1
	}
}

# Cyclic references should be caught on ? as well.
task CyclicReferenceList {
	Test -Task ? "Task 'test2': Cyclic reference to 'test1'.*At *${Separator}z.build.ps1:*InvalidArgument*" {
		task test1 test2
		task test2 test1
	}
}

# Cyclic references should be caught on * as well.
task CyclicReferenceStar {
	Test -Task * "Task 'test2': Cyclic reference to 'test1'.*At *${Separator}z.build.ps1:3 *InvalidArgument*" {
		task test1 test2
		task test2 test1
	}
}

# On * missing references should be reported with location.
# On developing v2.14.6 some code used to fail this.
task MissingReferenceStar {
	Test -Task * "Task 'bad': Missing task 'missing'.*At *${Separator}z.build.ps1:3 *InvalidArgument*" {
		task good {}
		task bad missing
	}
}

task MissingCommaInJobs {
	$file = {
		task t1 t2 {}
	}

	$log = [System.Collections.Generic.List[object]]@()
	. Set-Mock Write-Warning {param($Message) $log.Add($Message)}

	($r = try {Invoke-Build . $file} catch {$_})
	equals $r[-1].FullyQualifiedErrorId 'PositionalParameterNotFound,Add-BuildTask'
	equals $log.Count 1
	equals $log[0] 'Check task parameters: Name and comma separated Jobs.'
}

<#
We use `throw "Dangling scriptblock.." -> fine, we get: (1) "Build ABORTED"; (2) Errors: 1.
But if we use `*Die` -> KO: (1) no "Build ABORTED"; (2) Errors: 0.
This is weird but we should keep `throw`.
NB: v2 works fine with *Die.
#>
task DanglingScriptblock {
	$file = {
		task t1
		42
		{bar}
	}

	$log = [System.Collections.Generic.List[object]]@()
	. Set-Mock Write-Warning {param($Message) $log.Add($Message)}

	$err = ''
	($r = try {Invoke-Build . $file} catch {$err = $_})
	$r = Remove-Ansi $r
	assert (($r | Out-String) -like "ERROR: Dangling scriptblock at *${Separator}Invalid.test.ps1:*Build ABORTED *${Separator}Invalid.test.ps1. 0 tasks*")

	$err
	assert ("$err" -like "Dangling scriptblock at *${Separator}Invalid.test.ps1:*")
	equals $err.InvocationInfo.ScriptName $BuildFile

	equals $log.Count 2
	equals $log[0] 'Unexpected output: 42.'
	equals $log[1] 'Unexpected output: bar.'
}

# v4.1.1
task InvalidParameterResult {
	($r = try {Invoke-Build -Result 1} catch {$_})
	equals "$r" 'Invalid parameter Result.'
	equals $r.FullyQualifiedErrorId Invoke-Build.ps1
}

# Get Mandatory value for the command and parameter (true or false for a single
# attribute). The command must exist, the parameter may be missing (nothing is
# returned).
function Get-Mandatory($CommandName, $ParameterName) {
	foreach($p in (Get-Command $CommandName).Parameters.Values) {
		if ($p.Name -eq $ParameterName) {
			foreach($a in $p.Attributes) {
				if ($a -is [System.Management.Automation.ParameterAttribute]) {
					$a.Mandatory
				}
			}
		}
	}
}

# Test commands with Mandatory parameters.
task MandatoryParameters {
	# test `task` and `Get-Mandatory` itself
	equals (Get-Mandatory task Name) $true
	equals (Get-Mandatory task Jobs) $false
	equals (Get-Mandatory task bar)

	# test other commands
	equals (Get-Mandatory error Task) $true
	equals (Get-Mandatory property Name) $true
	equals (Get-Mandatory Get-BuildSynopsis Task) $true
	equals (Get-Mandatory exec Command) $true
	equals (Get-Mandatory use Path) $true
}

# https://github.com/nightroman/Invoke-Build/issues/171
task DoNotAddTasksAfterLoading {
	try {
		Invoke-Build t1 {
			Enter-Build {
				task bad
			}
			task t1
		}
		throw
	}
	catch {
		equals "$_" "Task 'bad': Cannot add tasks."
	}
}

# Task names cannot start with `?`.
task InvalidTaskName {
	try {
		Invoke-Build . {
			task ?bad
		}
		throw
	}
	catch {
		equals "$_" "Task '?bad': Invalid task name."
	}
}
