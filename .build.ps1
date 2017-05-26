
<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)

.Description
	TASKS AND REQUIREMENTS
	Run tests and compare results with expected
		- Assert-SameFile.ps1 https://www.powershellgallery.com/packages/Assert-SameFile
		- Invoke-PowerShell.ps1 https://www.powershellgallery.com/packages/Invoke-PowerShell
	Make the help file in PowerShell XML format
		- Helps.ps1 https://www.nuget.org/packages/Helps
	Convert markdown files to HTML for packages
		- pandoc https://github.com/jgm/pandoc/releases
	Push the release with a tag to GitHub
		- git
	Make and push the package to NuGet
		- NuGet
	Clean the project directory
#>

# Build script parameters are standard parameters
param(
	[switch]$NoTestDiff
)

# Ensure Invoke-Build works in the most strict mode.
Set-StrictMode -Version Latest

# Synopsis: Convert markdown files to HTML.
# <http://johnmacfarlane.net/pandoc/>
task Markdown {
	exec { pandoc.exe --standalone --from=markdown_strict --output=README.htm README.md }
	exec { pandoc.exe --standalone --from=markdown_strict --output=Release-Notes.htm Release-Notes.md }
}

# Synopsis: Remove generated and temp files.
task Clean {
	Remove-Item z, README.htm, Release-Notes.htm, Invoke-Build.*.nupkg -Force -Recurse -ErrorAction 0
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

function Copy-File($Destination) {
	Copy-Item -Destination $Destination `
	ib.cmd,
	Invoke-Build.ps1,
	Invoke-Builds.ps1,
	Invoke-Build-Help.xml,
	Resolve-MSBuild.ps1,
	README.htm,
	LICENSE.txt,
	Release-Notes.htm
}

# Synopsis: Make the package directory z\tools for NuGet.
task Package Markdown, Help, GitStatus, {
	# temp package folder
	Remove-Item [z] -Force -Recurse
	$null = mkdir z\tools

	# copy files
	Copy-File z\tools
}

# Synopsis: Install module and clean.
task Module Version, Markdown, Help, {
	# mirror module folder
	$dir = "$env:ProgramFiles\WindowsPowerShell\Modules\InvokeBuild\$Version"
	exec {$null = robocopy.exe InvokeBuild $dir /mir} (0..2)

	# copy files
	Copy-File $dir

	# make manifest
	Set-Content "$dir\InvokeBuild.psd1" @"
@{
	ModuleVersion = '$Version'
	ModuleToProcess = 'InvokeBuild.psm1'
	GUID = 'a0319025-5f1f-47f0-ae8d-9c7e151a5aae'
	Author = 'Roman Kuzmin'
	CompanyName = 'Roman Kuzmin'
	Copyright = '(c) 2011-2017 Roman Kuzmin'
	Description = 'Build and test automation in PowerShell'
	PowerShellVersion = '2.0'
	AliasesToExport = @('Invoke-Build', 'Invoke-Builds')
	PrivateData = @{
		PSData = @{
			Tags = 'Build', 'Test', 'Automation'
			ProjectUri = 'https://github.com/nightroman/Invoke-Build'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			IconUri = 'https://raw.githubusercontent.com/nightroman/Invoke-Build/master/ib.png'
			ReleaseNotes = 'https://github.com/nightroman/Invoke-Build/blob/master/Release-Notes.md'
		}
	}
}
"@
},
Clean

# Synopsis: Set $script:Version.
task Version {
	# get and test version
	($script:Version = (Get-BuildVersion).ToString())
	$r = .{ switch -Regex -File Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {return $Matches[1]}} }
	assert ($r -eq $Version) 'Invoke-Build and Release-Notes versions mismatch.'
}

# Synopsis: Make the NuGet package.
task NuGet Version, Package, {
	$text = @'
Invoke-Build is a build and test automation tool which invokes tasks defined in
PowerShell v2.0+ scripts. It is similar to psake but arguably easier to use and
more powerful. It is complete, bug free, well covered by tests.
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
		<developmentDependency>true</developmentDependency>
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
	exec { NuGet push "Invoke-Build.$Version.nupkg" -Source nuget.org }
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

# Synopsis: Test and check expected output.
# Requires PowerShelf/Assert-SameFile.ps1
task Test3 {
	# invoke tests, get output and result
	$output = Invoke-Build . Tests\.build.ps1 -Result result -Summary | Out-String -Width:200
	if ($NoTestDiff) {return}

	# process and save the output
	$resultPath = "$BuildRoot\Invoke-Build-Test.log"
	$samplePath = "$HOME\data\Invoke-Build-Test.$($PSVersionTable.PSVersion.Major).log"
	$output = $output -replace '\d\d:\d\d:\d\d(?:\.\d+)?( )? *', '00:00:00.0000000$1'
	[System.IO.File]::WriteAllText($resultPath, $output, [System.Text.Encoding]::UTF8)

	# compare outputs
	Assert-SameFile $samplePath $resultPath $env:MERGE
	Remove-Item $resultPath
}

# Synopsis: Test with PowerShell v2.
task Test2 {
	$diff = if ($NoTestDiff) {'-NoTestDiff'}
	exec {powershell.exe -Version 2 -NoProfile Invoke-Build Test3 $diff}
}

# Synopsis: Test with PowerShell v6.
task Test6 -If $env:powershell6 {
	$diff = if ($NoTestDiff) {'-NoTestDiff'}
	exec {& $env:powershell6 -NoProfile Invoke-Build Test3 $diff}
}

# Synopsis: Test v3+ and v2.
task Test Test3, Test2, Test6

# Synopsis: The default task: make, test, clean.
task . Help, Test, Clean
