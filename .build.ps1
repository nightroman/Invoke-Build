
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)

.Description
	The script automates tasks like:
	* Clean the project directory
	* Run tests and compare results with expected
	* Build the help file, PowerShell MAML format
	* Convert markdown files to HTML for packages
	* Push the release with a tag to GitHub
	* Make and push the package to NuGet
#>

# Build script parameters are standard parameters
param(
	[switch]$NoTestDiff
)

# Ensure Invoke-Build works in the most strict mode.
Set-StrictMode -Version Latest

# Import markdown tasks ConvertMarkdown and RemoveMarkdownHtml.
# <https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks>
Markdown.tasks.ps1

# Synopsis: Remove generated HTML and temp files.
task Clean RemoveMarkdownHtml, {
	Remove-Item z, Invoke-Build.*.zip, Invoke-Build.*.nupkg -Force -Recurse -ErrorAction 0
}

# Synopsis: Warn about not empty git status if .git exists.
task GitStatus -If (Test-Path .git) {
	$status = exec { git status -s }
	if ($status) {
		Write-Warning "Git status: $($status -join ', ')"
	}
}

# Synopsis: Build the PowerShell help file.
# <https://github.com/nightroman/Helps>
task Help {
	. Helps.ps1
	Convert-Helps Invoke-Build-Help.ps1 Invoke-Build-Help.xml
}

# Synopsis: Make the package directory z\tools for NuGet.
task Package ConvertMarkdown, Help, GitStatus, {
	# temp package folder
	Remove-Item [z] -Force -Recurse
	$null = mkdir z\tools\Tasks

	# copy files
	Copy-Item -Destination z\tools `
	Convert-psake.ps1,
	ib.cmd,
	Invoke-Build.ps1,
	Invoke-Build-Help.xml,
	Invoke-Builds.ps1,
	Invoke-TaskFromISE.ps1,
	LICENSE.txt,
	README.htm,
	Release-Notes.htm,
	Show-BuildGraph.ps1,
	Show-BuildTree.ps1,
	TabExpansionProfile.Invoke-Build.ps1

	# copy tasks
	exec { robocopy.exe Tasks z\tools\Tasks *.ps1 *.txt /S } (0..3)
}

# Synopsis: Set $script:Version.
task Version {
	# get and test version
	($script:Version = (Get-BuildVersion).ToString())
	$r = Select-String -SimpleMatch "Invoke-Build $Version" -Path Invoke-Build.ps1
	assert ($r) 'Missing or outdated line Invoke-Build <version>.'
}

# Synopsis: Make the zip package.
task Zip Version, Package, {
	Set-Location z\tools
	exec { & 7z.exe a ..\..\Invoke-Build.$Version.zip * }
}

# Synopsis: Make the NuGet package.
task NuGet Version, Package, {
	$text = @'
Invoke-Build is a build and test automation tool which invokes tasks
defined in PowerShell scripts. It is similar to psake but arguably
easier to use and more powerful.
'@
	Set-Content z\Package.nuspec @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
	<metadata>
		<id>Invoke-Build</id>
		<version>$Version</version>
		<authors>Roman Kuzmin</authors>
		<owners>Roman Kuzmin</owners>
		<projectUrl>https://github.com/nightroman/Invoke-Build</projectUrl>
		<iconUrl>https://raw.githubusercontent.com/nightroman/Invoke-Build/master/ib.png</iconUrl>
		<licenseUrl>http://www.apache.org/licenses/LICENSE-2.0</licenseUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<summary>$text</summary>
		<description>$text</description>
		<tags>PowerShell Build Test Automation</tags>
		<releaseNotes>https://github.com/nightroman/Invoke-Build/blob/master/Release-Notes.md</releaseNotes>
	</metadata>
</package>
"@
	exec { NuGet pack z\Package.nuspec -NoDefaultExcludes -NoPackageAnalysis }
}

# Synopsis: Push with a version tag.
task PushRelease Version, {
	$changes = exec { git status --short }
	assert (!$changes) "Please, commit changes."

	exec { git push }
	exec { git tag -a "v$Version" -m "v$Version" }
	exec { git push origin "v$Version" }
}

# Synopsis: Push NuGet package.
task PushNuGet NuGet, {
	exec { NuGet push "Invoke-Build.$Version.nupkg" }
},
Clean

# Synopsis: Calls tests infinitely. NOTE: normal scripts do not use ${*}.
task Loop {
	for() {
		${*}.Tasks.Clear()
		${*}.Errors.Clear()
		${*}.Warnings.Clear()
		Invoke-Build . Tests\.build.ps1
	}
}

# Synopsis: Invoke Tests scripts and check expected output.
# Requires PowerShelf/Assert-SameFile.ps1
task Test {
	# invoke tests, get output and result
	$output = Invoke-Build . Tests\.build.ps1 -Result result -Summary | Out-String -Width:200
	if ($NoTestDiff) {return}

	assert (222 -eq $result.Tasks.Count) $result.Tasks.Count
	assert (45 -eq $result.Errors.Count) $result.Errors.Count
	assert ($result.Warnings.Count -ge 1)

	# process and save the output
	$resultPath = "$BuildRoot\Invoke-Build-Test.log"
	$samplePath = "$HOME\data\Invoke-Build-Test.$($PSVersionTable.PSVersion.Major).log"
	$output = $output -replace '\d\d:\d\d:\d\d(?:\.\d+)?( )? *', '00:00:00.0000000$1'
	[System.IO.File]::WriteAllText($resultPath, $output, [System.Text.Encoding]::UTF8)

	# compare outputs
	Assert-SameFile $samplePath $resultPath $env:MERGE
	Remove-Item $resultPath
}

# Synopsis: The default task: make and test all, then clean.
task . Help, Test, Clean
