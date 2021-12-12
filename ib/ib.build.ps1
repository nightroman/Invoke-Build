<#
.Synopsis
	Build script, https://github.com/nightroman/Invoke-Build
#>

param(
	[ValidateSet('Debug', 'Release')]
	[string]$Configuration = 'Release'
)

$VersionPatch = 0

# Synopsis: Remove files.
task clean {
	Invoke-Build clean ../.build.ps1
}

# Synopsis: Set $script:Version.
task version {
	$r = switch -Regex -File ../Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {$Matches[1]; break}}
	($script:Version = "$r.$VersionPatch")
}

# Synopsis: Set $script:Version.
task content -If (!(Test-Path content)) {
	Invoke-Build module ..\.build.ps1
}

# Synopsis: Make NuGet package.
task nuget version, content, {
	$env:NoWarn = 'NU5110,NU5111'
	exec { dotnet pack -c $Configuration -p:VersionPrefix=$Version -o . }
}

# Synopsis: Install the tool from package.
task install {
	exec { dotnet tool install --add-source . -g ib }
}

# Synopsis: Uninstall the tool.
task uninstall {
	dotnet tool uninstall -g ib
}

# Synopsis: Test the tool.
task test {
	exec { ib.exe ** ../Tests/ib.exe }
}

# Synopsis: Default task.
task . uninstall, nuget, install, test, clean
