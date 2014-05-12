
<#
.Synopsis
	Tests features moved from the obsolete wrapper.

.Example
	Invoke-Build * Wrapper.test.ps1
#>

# For doing anything significant scripts should either `if (!$WhatIf) {...}` or
# use the event function Enter-Build. Its pair Exit-Build is a good place for
# cleaning, even on failures. We do not use it in order to keep data on errors.
# Instead, the last task removes temp files.
function Enter-Build {
	# Make directories in here (many build files) and in the parent (one file).
	Remove-Item [z] -Force -Recurse
	$null = mkdir z\1\2
}

task ParentHasManyCandidates {
	Set-Location z
	$PWD.Path
	$tasks = Invoke-Build ??
	assert ($tasks.Contains('AllTestScripts'))
}

task GrandParentHasManyCandidates {
	Set-Location z\1
	$PWD.Path
	$tasks = Invoke-Build ??
	assert ($tasks.Contains('AllTestScripts'))
}

task MakeSingleScript {
	'task SingleScript' > z\test.build.ps1
}

task ParentHasOneCandidate MakeSingleScript, {
	Set-Location z\1
	$PWD.Path
	$tasks = Invoke-Build ??
	assert ($tasks.Contains('SingleScript'))
}

task GrandParentHasOneCandidate MakeSingleScript, {
	Set-Location z\1\2
	$PWD.Path
	$tasks = Invoke-Build ??
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
	$tasks = Invoke-Build ??

	# restore the hook
	$env:InvokeBuildGetFile = $saved

	# test: the script returned by the hook is invoked
	assert ($tasks.Contains('MissingProperty'))
}

task Summary {
	# build succeeds
	@'
<##> task task1 { Start-Sleep -Milliseconds 1 }
<##> task . task1
'@ > z\test.build.ps1
	$log = Invoke-Build . z\test.build.ps1 -Summary | Out-String
	Write-Build Magenta $log
	assert ($log -like '*Build Summary*00:00:00*task1*\z\test.build.ps1:1*00:00:00*.*\z\test.build.ps1:2*')

	# build fails
	@'
<##> task task1 { throw 'Demo error in task1.' }
<##> task . (job task1 -Safe)
'@ > z\test.build.ps1
	$log = Invoke-Build . z\test.build.ps1 -Summary | Out-String
	Write-Build Magenta $log
	assert ($log -like '*Build Summary*00:00:00*task1*\z\test.build.ps1:1*Demo error in task1.*00:00:00*.*\z\test.build.ps1:2*')
}

#! Fixed differences of PS v2/v3
task StarsMissingDirectory {
	$$ = try {Invoke-Build ** miss} catch {$_}
	assert ($$ -like "Missing directory '*\Demo\miss'.")
}

#! Test StarsMissingDirectory first
task Stars StarsMissingDirectory, {
	# no .test.ps1 files
	$r = Invoke-Build **, ? z
	assert (!$r)
	$r = Invoke-Build **, ?? z
	assert (!$r)

	# fast task info, test first and last to be sure that there is not a header or footer
	$r = Invoke-Build **, ?
	assert ($r[0].Name -eq 'PreTask1' -and $r[0].Jobs -eq '{}')
	assert ($r[-1].Name -eq '.' -and $r[-1].Jobs -like 'ParentHasManyCandidates, *, Summary, {}' -and $r[-1].Synopsis -eq 'Call tests and clean.')

	# full task info
	$r = Invoke-Build **, ??
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
<##> task . {
	$d.Platform = $Platform
	$d.Configuration = $Configuration
}
'@ > z.build.ps1

	$d = @{}
	Invoke-Build
	assert ($d.Platform -ceq 'Win32' -and $d.Configuration -ceq 'Release')

	$d = @{}
	Invoke-Build -Platform x64 -Configuration Debug
	assert ($d.Platform -ceq 'x64' -and $d.Configuration -ceq 'Debug')

	$d = @{}
	Invoke-Build -Parameters @{Platform = 'x64'; Configuration = 'Debug'}
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
<##> task . {
	$d.Own1 = $Own1
	$d.File = $File
}
'@ > z.build.ps1

	$d = @{}
	Invoke-Build
	assert ($d.Own1 -ceq 'default1' -and $d.File -ceq 'default2')

	$d = @{}
	Invoke-Build -Parameter @{Own1 = 'custom1'; File = 'custom2'}
	assert ($d.Own1 -ceq 'custom1' -and $d.File -ceq 'custom2')

	$$ = try { Invoke-Build -Own1 '' -Parameter @{File = ''} } catch {$_}
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
<##> task .
'@ > z\.build.ps1

	Set-Location z
	$$ = try { Invoke-Build ? } catch {$_}
	assert ($$ -like "*Missing ')' in function parameter list.*")

	Set-Location $BuildRoot
	Remove-Item z\.build.ps1
}

task DynamicMissingScript {
	Set-Location $env:TEMP

	# missing custom
	$$ = try {Invoke-Build . missing.ps1} catch {$_}
	assert ($$ -like "Missing script '*\missing.ps1'.")
	assert ($$.InvocationInfo.Line -like '*{Invoke-Build . missing.ps1}*')

	# missing default
	$$ = try {Invoke-Build} catch {$_}
	assert ($$ -like 'Missing default script.')
	assert ($$.InvocationInfo.Line -like '*{Invoke-Build}*')
}

# Synopsis: Call tests and clean.
task . `
ParentHasManyCandidates,
GrandParentHasManyCandidates,
ParentHasOneCandidate,
GrandParentHasOneCandidate,
InvokeBuildGetFile,
Summary,
{
	Remove-Item z -Force -Recurse
}
