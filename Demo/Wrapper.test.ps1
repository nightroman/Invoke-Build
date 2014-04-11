
<#
.Synopsis
	Tests the wrapper script Build.ps1.

.Example
	Invoke-Build * Wrapper.test.ps1
#>

# Skip all preparations on WhatIf calls (when Tree and Comment are tested).
# Well written scripts should do this check and skip unwanted actions.
if (!$WhatIf) {
	# Build.ps1 can be invoked as ..\Build.ps1 from this script tasks. But we use
	# the alias set but 'use' instead, just in order to show that 'use' works not
	# only for .NET framework directory tools but for any tools, scripts as well.
	use .. Build

	# Make directories in here (many build files) and in the parent (one file).
	Remove-Item [z] -Force -Recurse
	$null = mkdir z\1\2
}

task ParentHasManyCandidates {
	Set-Location z
	$PWD.Path
	$tasks = Build ??
	assert ($tasks.Contains('AllTestScripts'))
}

task GrandParentHasManyCandidates {
	Set-Location z\1
	$PWD.Path
	$tasks = Build ??
	assert ($tasks.Contains('AllTestScripts'))
}

task MakeSingleScript {
	'task SingleScript' > z\test.build.ps1
}

task ParentHasOneCandidate MakeSingleScript, {
	Set-Location z\1
	$PWD.Path
	$tasks = Build ??
	assert ($tasks.Contains('SingleScript'))
}

task GrandParentHasOneCandidate MakeSingleScript, {
	Set-Location z\1\2
	$PWD.Path
	$tasks = Build ??
	assert ($tasks.Contains('SingleScript'))
}

task InvokeBuildGetFile {
	# register the hook by the environment variable
	$saved = $env:InvokeBuildGetFile
	$env:InvokeBuildGetFile = "$BuildRoot\z\1\InvokeBuildGetFile.ps1"

	# make the hook script which gets a build file
	#! `> $env:InvokeBuildGetFile` fails in [ ]
	$path = "$BuildRoot\Property.test.ps1"
	[System.IO.File]::WriteAllText($env:InvokeBuildGetFile, "'$path'")

	# invoke (remove the test script, if any)
	Set-Location z
	Remove-Item test.build.ps1 -ErrorAction 0
	$PWD.Path
	$tasks = Build ??

	# restore the hook
	$env:InvokeBuildGetFile = $saved

	# test: the script returned by the hook is invoked
	assert ($tasks.Contains('MissingProperty'))
}

task Tree {
	# no task
	$log = Build -File Wrapper.test.ps1 -Tree | Out-String
	$log
	assert ($log -like '*ParentHasManyCandidates (.)*TreeAndComment (.)*    Tree (TreeAndComment)*        Tree (TreeAndComment)*')
	assert (!$log.Contains('#'))

	# ? task has the same effect
	$log2 = Build -File Wrapper.test.ps1 -Tree | Out-String
	assert ($log2 -eq $log)
}

task Comment {
	# -Comment works on its own
	$log = Build . Wrapper.test.ps1 -Comment | Out-String
	$log

	# -Comment works with -Tree with the same effect
	$log2 = Build . Wrapper.test.ps1 -Tree -Comment | Out-String
	assert ($log2 -eq $log)

	# ensure comments are there
	$log = $log -replace '\r\n', '='
	assert ($log.Contains('=# Call tests and clean.=# The comment is tested.=.=    ParentHasManyCandidates (.)=')) $log
	assert ($log.Contains('=    <#=    Call tree tests.=    The comment is tested.=    #>=    TreeAndComment (.)=        Tree (TreeAndComment)=')) $log
}

<#
Call tree tests.
The comment is tested.
#>
task TreeAndComment Tree, Comment

task Summary {
	# to skip some checks on debugging/tracing
	$debugging = Test-Path Variable:\_Debugger

	# fake
	$log = [System.Collections.ArrayList]@()
	function Write-Host($Text, $ForegroundColor) { $null = $log.Add($Text) }

	# build succeeds
	@'
task task1 { Start-Sleep -Milliseconds 1 }
task . task1
'@ > z\test.build.ps1
	Build . z\test.build.ps1 -Summary
	$text = ($log -join "`r`n")
	Write-Build Magenta $text
	assert ($debugging -or ($text -like '*- Build Summary -*00:00:00*task1*\z\test.build.ps1:1*00:00:00*.*\z\test.build.ps1:2'))

	# build fails
	@'
task task1 { throw 'Demo error in task1.' }
task . (job task1 -Safe)
'@ > z\test.build.ps1
	$log = [System.Collections.ArrayList]@()
	Build . z\test.build.ps1 -Summary
	$text = ($log -join "`r`n")
	Write-Build Magenta $text
	assert ($debugging -or ($text -like '*- Build Summary -*00:00:00*task1*\z\test.build.ps1:1*Demo error in task1.*00:00:00*.*\z\test.build.ps1:2'))
}

task TreeTaskNotDefined {
	[System.IO.File]::WriteAllText("$BuildRoot\z\test.build.ps1", {
		task task1 missing, {}
		task . task1, {}
	})
	Build . z\test.build.ps1 -Tree
}

task TreeCyclicReference {
	[System.IO.File]::WriteAllText("$BuildRoot\z\test.build.ps1", {
		task task1 task2
		task task2 task1
		task . task1
	})
	Build . z\test.build.ps1 -Tree
}

#! Fixed differences of PS v2/v3
task StarsMissingDirectory {
	$$ = try {Build ** miss} catch {$_}
	assert ($$ -like "Missing directory '*\Demo\miss'.")
}

#! Test StarsMissingDirectory first
task Stars StarsMissingDirectory, {
	# no .test.ps1 files
	$r = Build **, ? z
	assert (!$r)
	$r = Build **, ?? z
	assert (!$r)

	# fast task info, test first and last to be sure that there is not a header or footer
	$r = Build **, ?
	assert ($r[0] -match '\\Alter\.test\.ps1\(\d+\): PreTask1$')
	assert ($r[-1] -match '\\Wrapper\.test\.ps1\(\d+\): \.$')

	# full task info
	$r = Build **, ??
	assert ($r.Count -ge 10) # *.test.ps1 files
	assert ($r[0] -is [System.Collections.Specialized.OrderedDictionary])
	assert ($r[-1] -is [System.Collections.Specialized.OrderedDictionary])
}

# fixed v2.4.5 cmdlet binding
task DynamicExampleParam {
	Set-Location z
	@'
param(
	[Parameter()]
	$Platform = 'Win32',
	$Configuration = 'Release'
)
task . {
	$d.Platform = $Platform
	$d.Configuration = $Configuration
}
'@ > z.build.ps1

	$d = @{}
	Build
	assert ($d.Platform -ceq 'Win32' -and $d.Configuration -ceq 'Release')

	$d = @{}
	Build -Platform x64 -Configuration Debug
	assert ($d.Platform -ceq 'x64' -and $d.Configuration -ceq 'Debug')

	$d = @{}
	Build -Parameters @{Platform = 'x64'; Configuration = 'Debug'}
	assert ($d.Platform -ceq 'x64' -and $d.Configuration -ceq 'Debug')

	Remove-Item z.build.ps1
}

task DynamicConflictParam {
	Set-Location z
	@'
param(
	$Own1 = 'default1',
	$File = 'default2'
)
task . {
	$d.Own1 = $Own1
	$d.File = $File
}
'@ > z.build.ps1

	$d = @{}
	Build
	assert ($d.Own1 -ceq 'default1' -and $d.File -ceq 'default2')

	$d = @{}
	Build -Parameter @{Own1 = 'custom1'; File = 'custom2'}
	assert ($d.Own1 -ceq 'custom1' -and $d.File -ceq 'custom2')

	$$ = try { Build -Own1 '' -Parameter @{File = ''} } catch {$_}
	assert ($$ -like "*A parameter cannot be found that matches parameter name 'Own1'.")

	Remove-Item z.build.ps1
}

#! keep it as it is, weird
task DynamicSyntaxError {
	@'
param(
	$a1
	$a2
)
task .
'@ > z\.build.ps1

	Set-Location z
	$$ = try { Build ? } catch {$_}
	assert ($$ -like "*Missing ')' in function parameter list.*")

	Set-Location $BuildRoot
	Remove-Item z\.build.ps1
}

task DynamicMissingScript {
	Set-Location $env:TEMP

	# missing custom
	$$ = try {Build . missing.ps1} catch {$_}
	assert ($$ -like "Missing script '*\missing.ps1'.")
	assert ($$.InvocationInfo.Line -like '*{Build . missing.ps1}*')

	# missing default
	$$ = try {Build} catch {$_}
	assert ($$ -like 'Missing default script.')
	assert ($$.InvocationInfo.Line -like '*{Build}*')
}

# Call tests and clean.
# The comment is tested.
task . `
ParentHasManyCandidates,
GrandParentHasManyCandidates,
ParentHasOneCandidate,
GrandParentHasOneCandidate,
InvokeBuildGetFile,
TreeAndComment,
Summary,
(job TreeTaskNotDefined -Safe),
(job TreeCyclicReference -Safe),
{
	$e = error TreeTaskNotDefined
	assert ("$e" -like "Task 'task1': Missing task 'missing'.*At *z\test.build.ps1:2 *")

	$e = error TreeCyclicReference
	assert ("$e" -like "Task 'task2': Cyclic reference to 'task1'.*At *z\test.build.ps1:3 *")

	Remove-Item z -Force -Recurse
}
