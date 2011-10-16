
<#
.Synopsis
	Tests the wrapper script Build.ps1.

.Example
	Invoke-Build . Wrapper.build.ps1
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

	# This directory has many build files, the default is
	$ManyDefault = Convert-Path (Resolve-Path .build.ps1)

	# This path will represent a single build file
	$OneDefault = "$BuildRoot\z\test.build.ps1"
}

task ParentHasManyCandidates {
	Set-Location z
	$PWD.Path
	$log = Build ?
	$log
	assert ($log[0].StartsWith("Build ? $ManyDefault"))
}

task GrandParentHasManyCandidates {
	Set-Location z\1
	$PWD.Path
	$log = Build ?
	$log
	assert ($log[0].StartsWith("Build ? $ManyDefault"))
}

task MakeSingleScript {
	'task .' > z\test.build.ps1
}

task ParentHasOneCandidate MakeSingleScript, {
	Set-Location z\1
	$PWD.Path
	$log = Build ?
	$log
	assert ($log[0].StartsWith("Build ? $OneDefault"))
}

task GrandParentHasOneCandidate MakeSingleScript, {
	Set-Location z\1\2
	$PWD.Path
	$log = Build ?
	$log
	assert ($log[0].StartsWith("Build ? $OneDefault"))
}

task InvokeBuildGetFile {
	# register the hook by the environment variable
	$saved = $env:InvokeBuildGetFile
	$env:InvokeBuildGetFile = "$BuildRoot\z\1\InvokeBuildGetFile.ps1"

	# make the hook script which gets a build file
	$path = "$BuildRoot\Property.build.ps1"
	"'$path'" > $env:InvokeBuildGetFile

	# invoke (remove the test script, if any)
	Set-Location z
	Remove-Item test.build.ps1 -ErrorAction 0
	$PWD.Path
	$log = Build ?
	$log

	# restore the hook
	$env:InvokeBuildGetFile = $saved

	# test: the script returned by the hook is invoked
	assert ($log[0].StartsWith("Build ? $path"))
}

task Tree {
	# no task
	$log = Build -File Wrapper.build.ps1 -Tree | Out-String
	$log
	assert ($log -like '*ParentHasManyCandidates (.)*TreeAndComment (.)*    Tree (TreeAndComment)*        Tree (TreeAndComment)*')
	assert (!$log.Contains('#'))

	# ? task has the same effect
	$log2 = Build -File Wrapper.build.ps1 -Tree | Out-String
	assert ($log2 -eq $log)
}

task Comment {
	# -Comment works on its own
	$log = Build . Wrapper.build.ps1 -Comment | Out-String
	$log

	# -Comment works with -Tree with the same effect
	$log2 = Build . Wrapper.build.ps1 -Tree -Comment | Out-String
	assert ($log2 -eq $log)

	# ensure comments are there
	$log = $log -replace '\r\n', '='
	assert ($log.Contains('\Demo\Wrapper.build.ps1==# Call tests and clean.=# The comment is tested.=.=    ParentHasManyCandidates (.)=')) $log
	assert ($log.Contains('=    <#=    Call tree tests.=    The comment is tested.=    #>=    TreeAndComment (.)=        Tree (TreeAndComment)=')) $log
}

<#
Call tree tests.
The comment is tested.
#>
task TreeAndComment Tree, Comment

task Summary {
	# fake
	function Write-Host($Text, $ForegroundColor) { $Text }

	# build succeeds
	@'
task task1 { Start-Sleep -Milliseconds 1 }
task . task1
'@ > z\test.build.ps1
	$log = Build . z\test.build.ps1 -Summary | Out-String
	$log
	assert ($log -match '00:00:00\.\d+ task1 \S+?\\test\.build\.ps1:1\r\n00:00:00\.\d+ \. \S+?\\test\.build\.ps1:2')

	# build fails
	@'
task task1 { throw 'Demo error in task1.' }
task . @{task1=1}
'@ > z\test.build.ps1
	$log = Build . z\test.build.ps1 -Summary | Out-String
	$log
	assert ($log -match '(?s)00:00:00\.\d+ task1 \S+?\\test\.build\.ps1:1\r\nDemo error in task1.*00:00:00\.\d+ \. \S+?\\test\.build\.ps1:2')
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
{
	Remove-Item z -Force -Recurse
}
