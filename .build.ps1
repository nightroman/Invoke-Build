
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)

.Description
	There is nothing to compile in this project. But Invoke-Build is suitable
	for automating all operations on project files, not just classic builds.

.Link
	Invoke-Build
#>

param
(
	[switch]$SkipTestDiff
)

# Set strict mode
Set-StrictMode -Version 2

# Requires: 7z.exe
Set-Alias 7z @(Get-Command 7z)[0].Definition

# Example of imported tasks and a case of empty dummy tasks created on errors.
# <https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks>
try { Markdown.tasks.ps1 }
catch { task ConvertMarkdown; task RemoveMarkdownHtml }

# Example of using imported tasks (ConvertMarkdown, RemoveMarkdownHtml) and an
# application (7z.exe). It also shows a dependent task referenced after the
# script job.
# The task prepares files, archives them, and then cleans.
task Zip ConvertMarkdown, Help, UpdateScript, GitStatus, {
	exec {
		& 7z a Invoke-Build.$(Get-BuildVersion).zip @(
			'Demo'
			'Invoke-Build.ps1'
			'Invoke-Build.ps1-Help.xml'
			'LICENSE.txt'
			'README.htm'
			'Release Notes.htm'
		)
	}
	Remove-Item Invoke-Build.ps1-Help.xml
},
RemoveMarkdownHtml

# Example of a conditional task. It warns about not empty git status if .git
# exists. The task is not invoked if .git is missing due to the condition.
task GitStatus -If (Test-Path .git) {
	$status = exec { git status -s }
	if ($status) {
		Write-Warning "Git status: $($status -join ', ')"
	}
}

# Example of 'assert'. Copies Invoke-Build.ps1 from its working location to the
# project home. Fails if the project file is newer, it is not supposed to be.
task UpdateScript {
	$target = Get-Item Invoke-Build.ps1 -ErrorAction 0
	$source = Get-Item (Get-Command Invoke-Build.ps1).Definition
	assert (!$target -or ($target.LastWriteTime -le $source.LastWriteTime))
	Copy-Item $source.FullName, "$($source.FullName)-Help.xml" .
}

# Tests Demo scripts and compares the output with expected. It creates and
# keeps Invoke-Build-Test.log in $env:TEMP. Then it compares it with a new
# output file in this directory. If they are the same then the new file is
# removed. Otherwise an application $env:MERGE is started.
task Test {
	# invoke tests, get the output and result
	$output = Invoke-Build . Demo\.build.ps1 -Result result | Out-String -Width:9999

	assert ($result.Tasks.Count -eq 27) $result.Tasks.Count
	assert ($result.AllTasks.Count -eq 107) $result.AllTasks.Count

	assert ($result.ErrorCount -eq 0) $result.AllErrorCount
	assert ($result.AllErrorCount -eq 20) $result.AllErrorCount

	assert ($result.WarningCount -ge 1)
	assert ($result.AllWarningCount -ge 1)

	assert ($result.Messages.Count -ge 1)
	assert ($result.AllMessages.Count -ge 21)

	if ($SkipTestDiff) { return }

	# process and save the output
	$outputPath = 'Invoke-Build-Test.log'
	$samplePath = "$env:TEMP\Invoke-Build-Test.log"
	$output = $output -replace '\d\d:\d\d:\d\d(?:\.\d+)?', '00:00:00.0000'
	Set-Content $outputPath $output

	# compare outputs
	$toCopy = $false
	if (Test-Path $samplePath) {
		$sample = (Get-Content $samplePath) -join "`r`n"
		if ($output -ceq $sample) {
			Write-BuildText Green 'The result is expected.'
			Remove-Item $outputPath
		}
		else {
			Write-Warning 'The result is not the same as expected.'
			if ($env:MERGE) {
				& $env:MERGE $outputPath $samplePath
			}
			$toCopy = 1 -eq (Read-Host 'Save the result as expected? [1] Yes [Enter] No')
		}
	}
	else {
		$toCopy = $true
	}

	# copy actual to expected
	if ($toCopy) {
		Write-BuildText Cyan 'Saving the result as expected.'
		Move-Item $outputPath $samplePath -Force
	}
}

# Calls the tests infinitely.
task Loop {
	for(;;) {
		Invoke-Build . Demo\.build.ps1
	}
}

# Build the XML help.
task Help {
	$script = (Get-Command Invoke-Build.ps1).Definition
	$dir = Split-Path $script

	. Helps.ps1
	Convert-Helps Invoke-Build.ps1-Help.ps1 $dir\Invoke-Build.ps1-Help.xml
}

# The default task. It tests all and cleans.
task . Help, Test, Zip, {
	# remove zip
	Remove-Item Invoke-Build.$(Get-BuildVersion).zip
}
