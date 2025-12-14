<#
.Synopsis
	Build script (https://github.com/nightroman/Invoke-Build)

.Description
	TASKS AND REQUIREMENTS
	Run tests and compare results with expected
		- Assert-SameFile.ps1 https://www.powershellgallery.com/packages/Assert-SameFile
		- Invoke-PowerShell.ps1 https://www.powershellgallery.com/packages/Invoke-PowerShell
	Make help in PowerShell XML format
		- Helps.ps1 https://www.nuget.org/packages/Helps
	Convert markdown files to HTML
		- pandoc https://github.com/jgm/pandoc/releases
	Push to GitHub with a tag
		- git
	Make and push the NuGet package
		- NuGet
	Clean the project directory
#>

# Build script parameters
param(
	[switch]$NoTestDiff
)

# Ensure IB works in the strict mode.
Set-StrictMode -Version Latest
$ProgressPreference = 0

# Synopsis: Convert markdown files to HTML.
# <http://johnmacfarlane.net/pandoc/>
task markdown {
	function Convert-Markdown($Name) {pandoc.exe --standalone --from=gfm "--output=$Name.html" "--metadata=pagetitle=$Name" "$Name.md"}
	exec { Convert-Markdown README }
}

# Synopsis: Remove temp files.
task clean {
	remove z, *\z, *\z.*, README.html, Invoke-Build.*.nupkg, Tests\New-VSCodeTask\.vscode\tasks.json
	remove ib\bin, ib\obj, ib\ib.*.nupkg
}

# Synopsis: Build the PowerShell help file.
# <https://github.com/nightroman/Helps>
task help {
	. Helps.ps1
	Convert-Helps Help.ps1 Help.xml
}

# Synopsis: Set $Script:Version.
task version {
	($Script:Version = Get-BuildVersion Release-Notes.md '##\s+v(\d+\.\d+\.\d+)')
}

# Synopsis: Make the module folder.
task module version, markdown, help, {
	remove z

	# copy the module folder
	$dir = "$BuildRoot\z\InvokeBuild"
	Copy-Item Content $dir -Recurse

	# copy files without Invoke-Build.ps1
	Copy-Item -Destination $dir $(
		'Build-Checkpoint.ps1'
		'Build-Parallel.ps1'
		'Help.xml'
		'Resolve-MSBuild.ps1'
		'Show-TaskHelp.ps1'
		'README.html'
		'LICENSE'
	)

	# copy Invoke-Build.ps1 with version comment
	$text = Get-Content Invoke-Build.ps1 -Raw
	assert ($text -match '^<#\n')
	[System.IO.File]::WriteAllText("$dir\Invoke-Build.ps1", ("<# Invoke-Build $Version" + $text.Substring(2)))

	# make manifest
	[System.IO.File]::WriteAllText("$dir\InvokeBuild.psd1", @"
@{
	ModuleVersion = '$Version'
	RootModule = 'InvokeBuild.psm1'
	GUID = 'a0319025-5f1f-47f0-ae8d-9c7e151a5aae'
	Author = 'Roman Kuzmin'
	CompanyName = 'Roman Kuzmin'
	Copyright = '(c) Roman Kuzmin'
	Description = 'Build and test automation in PowerShell'
	PowerShellVersion = '3.0'
	AliasesToExport = 'Invoke-Build', 'Build-Checkpoint', 'Build-Parallel'
	VariablesToExport = @()
	FunctionsToExport = @()
	CmdletsToExport = @()
	PrivateData = @{
		PSData = @{
			Tags = 'Build', 'Test', 'Automation'
			ProjectUri = 'https://github.com/nightroman/Invoke-Build'
			LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'
			IconUri = 'https://raw.githubusercontent.com/nightroman/Invoke-Build/main/ib.png'
			ReleaseNotes = 'https://github.com/nightroman/Invoke-Build/blob/main/Release-Notes.md'
		}
	}
}
"@)

	# test line endings
	(Get-ChildItem $dir -Recurse -File -Exclude *.xml, *.html).ForEach{
		assert (!(Get-Content $_ -Raw).Contains("`r")) "Unexpected line ending CR: $_"
	}
}

# Synopsis: Make the NuGet package.
task nuget module, {
	# rename the folder
	Rename-Item z\InvokeBuild tools

	# summary and description
	$text = @'
Invoke-Build is a build and test automation tool which invokes tasks defined in
PowerShell v3.0+ scripts. It is similar to psake but arguably easier to use and
more powerful. It is complete, bug free, well covered by tests.
'@

	# icon
	Copy-Item ib.png z

	# manifest
	Set-Content z\Package.nuspec @"
<?xml version="1.0"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
	<metadata>
		<id>Invoke-Build</id>
		<version>$Version</version>
		<authors>Roman Kuzmin</authors>
		<owners>Roman Kuzmin</owners>
		<projectUrl>https://github.com/nightroman/Invoke-Build</projectUrl>
		<icon>ib.png</icon>
		<license type="expression">Apache-2.0</license>
		<description>$text</description>
		<tags>Build Automation PowerShell</tags>
		<releaseNotes>https://github.com/nightroman/Invoke-Build/blob/main/Release-Notes.md</releaseNotes>
		<developmentDependency>true</developmentDependency>
	</metadata>
</package>
"@

	# package
	exec { nuget pack z\Package.nuspec -NoDefaultExcludes -NoPackageAnalysis }
}

# Synopsis: Push with a version tag.
task pushAndTag version, {
	$changes = exec { git status --short }
	assert (!$changes) "Please, commit changes."

	exec { git push }

	$tag = "v$Version"
	exec { git tag -a $tag -m $tag }
	exec { git push origin $tag }
}

function last_release_notes {
	$text = Get-Content -Raw Release-Notes.md
	$re = [regex]'##\s+v(\d+\.\d+\.\d+)'
	$m1 = $re.Match($text)
	$m2 = $m1.NextMatch()
	assert ($m1.Success -and $m2.Success)
	$st = $m1.Index + $m1.Length
	$text.Substring($st, $m2.Index - $st)
}

# Synopsis: Create release from tag.
task newRelease version, {
	$tag = "v$Version"
	$url = "https://api.github.com/repos/nightroman/Invoke-Build/releases"
	$headers = [ordered]@{
		Accept = "application/vnd.github+json"
		Authorization = "Bearer $env:GITHUB_TOKEN"
		"X-GitHub-Api-Version" = "2022-11-28"
	}
	$body = [ordered]@{
		tag_name = $tag
		name = $tag
		body = last_release_notes
	} | ConvertTo-Json

	if (Confirm-Build $body) {
		$null = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body -ContentType application/json
	}
}

# Synopsis: Push, make tag, make release.
task pushRelease pushAndTag, newRelease

# Synopsis: Push NuGet package.
task pushNuGet nuget, {
	exec { nuget push "Invoke-Build.$Version.nupkg" -Source nuget.org -ApiKey (property NuGetApiKey) }
}

# Synopsis: Push PSGallery package.
task pushPSGallery module, {
	Publish-Module -Path z/InvokeBuild -NuGetApiKey (property NuGetApiKeyPS)
}

# Synopsis: Calls tests infinitely. NOTE: normal scripts do not use ${*}.
task loop {
	for() {
		${*}.Tasks.Clear()
		${*}.Errors.Clear()
		${*}.Warnings.Clear()
		Invoke-Build . Tests\1.build.ps1
	}
}

# Synopsis: Get dependencies.
task boot {
	Save-Script Invoke-PowerShell -Path . -Force
}

# Synopsis: Generate help.
task docs {
	$text = $(
		'# Invoke-Build Help'
		''
		foreach($_ in ./Help.ps1) {
			$name = $_.Command
			Convert-HelpToDocs.ps1 $name "Docs/help/$name.md"
			"- [$name]($name.md) - $($_.Synopsis)"
		}

		Convert-HelpToDocs.ps1 Resolve-MSBuild.ps1 Docs/help/Resolve-MSBuild.ps1.md
		"- [Resolve-MSBuild.ps1](Resolve-MSBuild.ps1.md) - $((Get-Help Resolve-MSBuild.ps1).Synopsis)"
	) -join "`n"
	Set-Content Docs/help/README.md $text -NoNewline
}

# Synopsis: Test Desktop.
task desktop {
	$diff = if ($NoTestDiff) {'-NoTestDiff'}
	exec { powershell -nop -c Invoke-Build test $diff }
}

# Synopsis: Test Core.
task core {
	$diff = if ($NoTestDiff) {'-NoTestDiff'}
	exec { pwsh -nop -c Invoke-Build test $diff }
}

# Synopsis: Test and check expected output.
# Requires PowerShelf/Assert-SameFile.ps1
task test {
	$ErrorView='NormalView'
	if ($Host.Name -eq 'FarHost') {$NoTestDiff = $true; Write-Warning "Skip test diff in FarHost."}

	# test, get output and result
	Invoke-Build . Tests\1.build.ps1 -Result result | Tee-Object -Variable output
	if ($NoTestDiff) {
		return
	}
	$output = $output | Out-String -Width:200
	$output = $output -replace '\d\d:\d\d:\d\d(?:\.\d+)?(\s)?\s*', '00:00:00.0000000$1'

	# process and save the output
	$samplePath = "$HOME\data\Invoke-Build.$PSEdition.log"
	$resultPath = "$samplePath.log"
	[System.IO.File]::WriteAllText($resultPath, $output)

	# compare outputs
	Assert-SameFile $samplePath $resultPath $env:MERGE
	Remove-Item $resultPath
}

# Synopsis: Make, test, clean.
task . help, desktop, core, clean
