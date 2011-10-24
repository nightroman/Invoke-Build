
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)

.Description
	The script automates project tasks like:
	* Clean the project directory
	* Run tests and compare results with expected
	* Build the help file (PowerShell MAML format)
	* Convert markdown files to HTML for packages
	* Create packages
		* zip for the project downloads
		* NuGet for the NuGet gallery
#>

param
(
	[switch]$SkipTestDiff
)

# Set strict mode
Set-StrictMode -Version 2

# Requires: 7z.exe
Set-Alias 7z @(Get-Command 7z)[0].Definition

# Import markdown tasks ConvertMarkdown and RemoveMarkdownHtml.
# <https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks>
Markdown.tasks.ps1

# Remove generated HTML and temp files.
task Clean RemoveMarkdownHtml, {
	Remove-Item z, Invoke-Build.ps1-Help.xml, Invoke-Build.*.zip, Invoke-Build.*.nupkg -Force -Recurse -ErrorAction 0
}

# Warn about not empty git status if .git exists.
task GitStatus -If (Test-Path .git) {
	$status = exec { git status -s }
	if ($status) {
		Write-Warning "Git status: $($status -join ', ')"
	}
}

# Copy Invoke-Build.ps1 and help from working location to the project.
# Fail (assert) if the project file is newer, it is not supposed to be.
task UpdateScript {
	$target = Get-Item Invoke-Build.ps1 -ErrorAction 0
	$source = Get-Item (Get-Command Invoke-Build.ps1).Definition
	assert (!$target -or ($target.LastWriteTime -le $source.LastWriteTime))
	Copy-Item $source.FullName, "$($source.FullName)-Help.xml" .

	$target = Get-Item Build.ps1 -ErrorAction 0
	$source = Get-Item (Get-Command x.ps1).Definition
	assert (!$target -or ($target.LastWriteTime -le $source.LastWriteTime))
	Copy-Item $source.FullName Build.ps1
}

# Build the PowerShell help file.
task Help {
	$script = (Get-Command Invoke-Build.ps1).Definition
	$dir = Split-Path $script
	. Helps.ps1
	Convert-Helps Invoke-Build.ps1-Help.ps1 $dir\Invoke-Build.ps1-Help.xml
}

# Make the package in z\tools for Zip and NuGet.
task Package ConvertMarkdown, Help, UpdateScript, GitStatus, {
	# temp package folder
	Remove-Item [z] -Force -Recurse
	$null = mkdir z\tools

	# copy project files
	Copy-Item -Destination z\tools -Recurse @(
		'Demo'
		'Build.ps1'
		'Invoke-Build.ps1'
		'LICENSE.txt'
	)

	# move generated files
	Move-Item -Destination z\tools @(
		'Invoke-Build.ps1-Help.xml'
		'README.htm'
		'Release-Notes.htm'
	)
}

# Make the package, test in it with Demo renamed to [ ] and clean.
#! It is not supposed to be called with other tasks.
task PackageTest Package, {
	# make it much harder with square brackets
	Move-Item -LiteralPath z\tools\Demo 'z\tools\[ ]'
	# test in the package using tools exactly from the package
	Set-Alias Invoke-Build "$BuildRoot\z\tools\Invoke-Build.ps1"
	Set-Location -LiteralPath 'z\tools\[ ]'
	..\Build.ps1

	# the last sanity check: expected package item count
	$count = (Get-ChildItem .. -Force -Recurse).Count
	assert ($count -eq 22) "Unexpected package item count: $count"
},
Clean

# Make the zip package.
task Zip Package, {
	Set-Location z\tools
	exec { & 7z a ..\..\Invoke-Build.$(Get-BuildVersion).zip * }
}

# Make the NuGet package.
task NuGet Package, {
	$text = @'
Invoke-Build.ps1 is a build automation tool implemented as a standalone
PowerShell script. It invokes tasks defined in build scripts written in
PowerShell with a few domain-specific language features. Build flow and
concepts are similar to MSBuild. Scripts are similar to psake but look more
like usual due to standard PowerShell parameters and script scope variables.
'@
	# nuspec
	Set-Content z\Package.nuspec @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
	<metadata>
		<id>Invoke-Build</id>
		<version>$(Get-BuildVersion)</version>
		<authors>Roman Kuzmin</authors>
		<owners>Roman Kuzmin</owners>
		<projectUrl>https://github.com/nightroman/Invoke-Build</projectUrl>
		<licenseUrl>http://www.apache.org/licenses/LICENSE-2.0</licenseUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<summary>$text</summary>
		<description>$text</description>
		<tags>powershell build automation</tags>
	</metadata>
</package>
"@
	# pack
	exec { NuGet pack z\Package.nuspec -NoDefaultExcludes }
}

# Make both zip and NuGet packages
task Pack Zip, NuGet

# Calls tests infinitely to be sure it works and nothing leaks.
task Loop {
	for(;;) {
		$BuildInfo.AllTasks.Clear()
		$BuildInfo.AllMessages.Clear()
		Invoke-Build . Demo\.build.ps1
	}
}

# * Test Demo scripts and compare the output with expected. Create and keep
# Invoke-Build-Test.log in %TEMP%. Then compare it with a new output file in
# this directory. If they are the same then remove the new file. Otherwise
# start %MERGE%.
# * After the test call UpdateScript.
task Test {
	# invoke tests, get the output and result
	$output = Invoke-Build . Demo\.build.ps1 -Result result | Out-String -Width:9999

	assert ($result.AllTasks.Count -eq 139) $result.AllTasks.Count
	assert ($result.Tasks.Count -eq 29) $result.Tasks.Count

	assert ($result.AllErrorCount -eq 28) $result.AllErrorCount
	assert ($result.ErrorCount -eq 0) $result.AllErrorCount

	assert ($result.AllWarningCount -ge 1)
	assert ($result.WarningCount -ge 1)

	assert ($result.AllMessages.Count -ge 1)
	assert ($result.Messages.Count -ge 1)

	if ($SkipTestDiff) { return }

	# process and save the output
	$outputPath = 'Invoke-Build-Test.log'
	$samplePath = "$env:TEMP\Invoke-Build-Test.log"
	$output = $output -replace '\d\d:\d\d:\d\d(?:\.\d+)?( )? *', '00:00:00.0000000$1'
	Set-Content $outputPath $output

	# compare outputs
	$toCopy = $false
	if (Test-Path $samplePath) {
		$sample = (Get-Content $samplePath) -join "`r`n"
		if ($output -ceq $sample) {
			Write-BuildText Green 'The result is not changed.'
			Remove-Item $outputPath
		}
		else {
			Write-Warning 'The result is changed.'
			if ($env:MERGE) {
				& $env:MERGE $outputPath $samplePath
			}
			do {} until ((Read-Host "[] Continue [1] Save the result") -match '^(1)?$')
			$toCopy = 1 -eq $matches[1]
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
},
UpdateScript

# Test some more and clean.
task . Help, Test, Clean
