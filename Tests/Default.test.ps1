
<#
.Synopsis
	Tests default build scripts resolution.
#>

task AmbigiousDefaultScript {
	Get-Item [z] | Remove-Item -Force -Recurse
	$null = mkdir z
	Push-Location z

	1 > z.1.build.ps1
	1 > z.2.build.ps1

	($r = try {Invoke-Build} catch {$_})
	assert ("$r" -like "*Ambiguous default script in '*\z'.")

	Pop-Location
	Remove-Item z -Force -Recurse
}

task ParentHasManyCandidates {
	Get-Item [z] | Remove-Item -Force -Recurse
	$null = mkdir z\1

	Push-Location z
	$tasks = Invoke-Build ??
	Pop-Location

	assert ($tasks.Contains('AllTestScripts'))

	Push-Location z\1
	$tasks = Invoke-Build ??
	Pop-Location

	assert ($tasks.Contains('AllTestScripts'))

	Remove-Item z -Force -Recurse
}

task ParentHasOneCandidate {
	Get-Item [z] | Remove-Item -Force -Recurse
	$null = mkdir z\1\2

	Set-Content z\test.build.ps1 'task SingleScript'

	Push-Location z\1
	$tasks = Invoke-Build ??
	Pop-Location

	assert $tasks.Contains('SingleScript')

	Push-Location z\1\2
	$tasks = Invoke-Build ??
	Pop-Location

	assert $tasks.Contains('SingleScript')

	Remove-Item z -Force -Recurse
}

task InvokeBuildGetFile {
	Get-Item [z] | Remove-Item -Force -Recurse
	$null = mkdir z\1

	# register the hook by the environment variable
	$saved = $env:InvokeBuildGetFile
	$env:InvokeBuildGetFile = "$BuildRoot\z\1\InvokeBuildGetFile.ps1"

	# make the hook script which gets this script as a build file
	Set-Content -LiteralPath $env:InvokeBuildGetFile "'$BuildFile'"

	# invoke (remove the test script, if any)
	Push-Location z
	$tasks = Invoke-Build ??
	Pop-Location

	# restore the hook
	$env:InvokeBuildGetFile = $saved

	# test: the script returned by the hook is invoked
	assert $tasks.Contains('InvokeBuildGetFile')

	Remove-Item z -Force -Recurse
}

task Summary {
	# build works
	Set-Content z.ps1 {
		task task1 { Start-Sleep -Milliseconds 1 }
		task . task1
	}
	($r = Invoke-Build . z.ps1 -Summary | Out-String)
	assert ($r -clike '*Build summary:*00:00:00* task1 *\z.ps1:2*00:00:00* . *\z.ps1:3*')

	# build fails
	Set-Content z.ps1 {
		task task1 { throw 'Demo error in task1.' }
		task . ?task1
	}
	($r = Invoke-Build . z.ps1 -Summary | Out-String)
	assert ($r -clike '*Build summary:*00:00:00* task1 *\z.ps1:2*Demo error in task1.*00:00:00* . *\z.ps1:3*')

	Remove-Item z.ps1
}

#! Fixed differences of PS v2/v3
task StarsMissingDirectory {
	($r = try {Invoke-Build ** miss} catch {$_})
	assert ($r -like "Missing directory '*\Tests\miss'.")
}

#! Test StarsMissingDirectory first
task Stars StarsMissingDirectory, {
	Get-Item [z] | Remove-Item -Force -Recurse
	$null = mkdir z

	# no .test.ps1 files
	$r = Invoke-Build **, ? z
	assert (!$r)
	$r = Invoke-Build **, ?? z
	assert (!$r)

	# fast task info, test first and last to be sure that there is not a header or footer
	$r = Invoke-Build **, ?
	equals $r[0].Name PreTask1
	equals $r[0].Jobs '{}'
	equals $r[-1].Name test-fail

	# full task info
	$r = Invoke-Build **, ??
	assert ($r.Count -ge 10) # *.test.ps1 files
	assert ($r[0] -is [System.Collections.Specialized.OrderedDictionary])
	assert ($r[-1] -is [System.Collections.Specialized.OrderedDictionary])

	Remove-Item z
}
