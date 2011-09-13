
<#
.Synopsis
	The build script of the project and also a master script example.

.Description
	There is nothing to compile in this project. But Invoke-Build is suitable
	for automating all operations on project files, not just classic builds.

	This script is an example of master build scripts. In contrast to classic
	scripts master build scripts are invoked directly, not by Invoke-Build.

	The advantage of master scripts is that they are much easier to call. This
	is especially true when they have a lot of parameters. The price is quite
	low, just a couple of dot-sourced calls in the beginning and the end:

		. Invoke-Build $BuildTask
		. Start-Build

	This script is used in the development and included into the published
	archive only as an example. It may not work in some environments, for
	example it requires 7z.exe and Invoke-Build.ps1 in the system path.

.Example
	># As far as it is a master script, it is called directly:

	.\Build.ps1 ?          # Show tasks and their relations
	.\Build.ps1 zip        # Invoke the Zip and related tasks
	.\Build.ps1 . -WhatIf  # Show what if the . task is called

.Link
	Invoke-Build
#>

# For a simple script like this one command without param() would be enough:
# . Invoke-Build $args
# The script still uses param(...) just in order to show how it works.
param
(
	$BuildTask,
	[switch]$WhatIf
)

# Master script step 1: Dot-source Invoke-Build with tasks and options.
# Then scripts do what they want but the goal is to create a few tasks.
. Invoke-Build $BuildTask -WhatIf:$WhatIf

# Invoke-Build does not change any settings, scripts do:
Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

# Required tools (to fail if missing).
Set-Alias 7z @(Get-Command 7z)[0].Definition

# Example of partial incremental build. Fails without Convert-Markdown.ps1. But
# the Zip task calls it protected and should still do its job, partially.
# * Input is all markdown files.
# * Output transforms input paths into output paths. [*]
# * And the job is to process each out-of-date input. [*]
# [*] Note use of 'process' blocks and variables $_ and $$ there.
task ConvertMarkdown `
-Inputs { Get-ChildItem -Filter *.md } `
-Outputs {process{ [System.IO.Path]::ChangeExtension($_, 'htm') }} `
{process{
	Convert-Markdown.ps1 $_ $$
}}

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
	Copy-Item $source.FullName .
}

# Example of a protected task call and use of 'error'. Makes the zip using HTML
# files, the latest script, etc. Calls ConvertMarkdown protected because it may
# fail. Then checks for an error and amends the command if needed.
task Zip @{ConvertMarkdown=1}, UpdateScript, GitStatus, {
	$exclude = if (error ConvertMarkdown) {} else {'-x!*.md'}
	exec { & 7z a Invoke-Build.$(Get-BuildVersion).zip * '-x!.git*' '-x!Test-Output.*' $exclude }
	Remove-Item *.htm
}

# Tests Demo scripts and compares the output with expected. It creates and
# keeps Invoke-Build-Test.log in $env:TEMP. Then it compares it with a new
# output file in this directory. If they are the same then the new file is
# removed. Otherwise an application $env:MERGE is started.
task Test {
	# invoke tests, get the output
	$output = Invoke-Build . Demo\.build.ps1 | Out-String -Width:9999

	# process and save the output
	$outputPath = 'Invoke-Build-Test.log'
	$samplePath = "$env:TEMP\Invoke-Build-Test.log"
	$output = $output -replace '\d\d:\d\d:\d\d\.\d+', '00:00:00.0000'
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
				& $env:MERGE $samplePath $outputPath
			}
			$toCopy = 1 -eq (Read-Host 'Save the result as expected? [1] Yes [Enter] No')
		}
	}
	else {
		$toCopy = $true
	}

	### copy actual to expected
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

# The default task. It tests all and cleans.
task . Test, Zip, {
	# remove zip
	Remove-Item Invoke-Build.$(Get-BuildVersion).zip

	# check the current and total build counters
	if (!(error ConvertMarkdown)) {
		# current
		assert ($BuildThis.TaskCount -eq 6) $BuildThis.TaskCount
		assert ($BuildThis.ErrorCount -eq 0) $BuildThis.ErrorCount
		# total
		assert ($BuildInfo.TaskCount -eq 96) $BuildInfo.TaskCount
		assert ($BuildInfo.ErrorCount -eq 18) $BuildInfo.ErrorCount
		assert ($BuildInfo.WarningCount -ge 1)
		assert ($BuildInfo.WarningCount -ge $BuildThis.WarningCount)
	}
}

# Master script step 2: Invoke build tasks. This is often the last command but
# this is not a requirement, for example scripts can do some post-build jobs.
. Start-Build
