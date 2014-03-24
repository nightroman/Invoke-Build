
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

param(
	[switch]$SkipTestDiff
)

# Ensure Invoke-Build works in the most strict mode.
# Version Latest checks indexes out of array bounds.
Set-StrictMode -Version Latest

# Import markdown tasks ConvertMarkdown and RemoveMarkdownHtml.
# <https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks>
Markdown.tasks.ps1

# Remove generated HTML and temp files.
task Clean RemoveMarkdownHtml, {
	Remove-Item z, Invoke-Build-Help.xml, Invoke-Build.*.nupkg -Force -Recurse -ErrorAction 0
}

# Warn about not empty git status if .git exists.
task GitStatus -If (Test-Path .git) {
	$status = exec { git status -s }
	if ($status) {
		Write-Warning "Git status: $($status -join ', ')"
	}
}

# Copy scripts and help from working location to the project.
# Fail if the project files are newer, to be resolved manually.
task UpdateScript {
	$from = Split-Path (Get-Command Build.ps1).Definition
	$files = @(
		'Build.ps1'
		'Invoke-Build.ps1'
		'Invoke-Build-Help.xml'
		'Invoke-Builds.ps1'
		'Show-BuildGraph.ps1'
		'TabExpansionProfile.Invoke-Build.ps1'
	)
	foreach($file in $files) {
		$file
		$s = Get-Item "$from\$file"
		$t = Get-Item $file -ErrorAction 0
		assert (!$t -or ($t.LastWriteTime -le $s.LastWriteTime)) "$s -> $t"
		Copy-Item $s.FullName $file
	}
}

# Build the PowerShell help file.
# <https://github.com/nightroman/Helps>
task Help {
	$dir = Split-Path (Get-Command Invoke-Build.ps1).Definition
	. Helps.ps1
	Convert-Helps Invoke-Build-Help.ps1 $dir\Invoke-Build-Help.xml
}

# Make the package directory z\tools for NuGet.
task Package ConvertMarkdown, Help, UpdateScript, GitStatus, {
	# temp package folder
	Remove-Item [z] -Force -Recurse
	$null = mkdir z\tools

	# copy project files
	Copy-Item -Destination z\tools `
	.\Build.ps1,
	.\Invoke-Build.ps1,
	.\Invoke-Builds.ps1,
	.\LICENSE.txt,
	.\Show-BuildGraph.ps1,
	.\TabExpansionProfile.Invoke-Build.ps1

	# move generated files
	Move-Item -Destination z\tools `
	.\Invoke-Build-Help.xml,
	.\README.htm,
	.\Release-Notes.htm
}

# Set $script:Version.
task Version {
	# get and test version
	($script:Version = (Get-BuildVersion).ToString())
	$r = Select-String -SimpleMatch "Invoke-Build $Version" -Path Invoke-Build.ps1
	assert ($r) 'Missing or outdated line Invoke-Build <version>.'
}

# Make the NuGet package.
task NuGet Version, Package, {
	$text = @'
Invoke-Build invokes specified tasks defined in a PowerShell script.
This process is called build. Tasks are pieces of code with optional
relations. Concepts are similar to MSBuild and psake.
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
		<licenseUrl>http://www.apache.org/licenses/LICENSE-2.0</licenseUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<summary>$text</summary>
		<description>$text</description>
		<tags>PowerShell Build Automation</tags>
	</metadata>
</package>
"@
	exec { NuGet pack z\Package.nuspec -NoDefaultExcludes -NoPackageAnalysis }
}

# Push with a version tag.
task PushRelease Version, {
	$changes = exec { git status --short }
	assert (!$changes) "Please, commit changes."

	exec { git push }
	exec { git tag -a "v$Version" -m "v$Version" }
	exec { git push origin "v$Version" }
}

# Push NuGet package.
task PushNuGet NuGet, {
	exec { NuGet push "Invoke-Build.$Version.nupkg" }
},
Clean

# Calls tests infinitely. NOTE: normal scripts do not use ${*}.
task Loop {
	for() {
		${*}.Tasks.Clear()
		${*}.Errors.Clear()
		${*}.Warnings.Clear()
		Invoke-Build . Demo\.build.ps1
	}
}

# UpdateScript, test Demo scripts, and compare the output file with the
# sample. Requires Assert-SameFile from PowerShelf.
task Test UpdateScript, {
	# invoke tests, get output and result
	$output = Invoke-Build . Demo\.build.ps1 -Result result | Out-String -Width:9999
	if ($SkipTestDiff) {return}

	assert (193 -eq $result.Tasks.Count) $result.Tasks.Count
	assert (38 -eq $result.Errors.Count) $result.Errors.Count
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

# Test all and clean.
task . Help, Test, Clean
