<#
.Synopsis
	Build script, https://github.com/nightroman/Invoke-Build
#>

param(
	[ValidateSet('Debug', 'Release')]
	[string]$Configuration = 'Release'
)

Set-StrictMode -Version Latest

# Synopsis: Remove files.
task clean {
	Invoke-Build clean ../1.build.ps1
}

# Synopsis: Set $Script:Version.
task version {
	($Script:Version = Get-BuildVersion ../Release-Notes.md '##\s+v(\d+\.\d+\.\d+)')
}

# Synopsis: Copy module files.
task content -If (!(Test-Path content)) {
	Invoke-Build module ../1.build.ps1
}

# Synopsis: Make NuGet package.
task nuget version, content, {
	$env:NoWarn = 'NU5110,NU5111'
	exec { dotnet pack -c $Configuration -p:VersionPrefix=$Version -o . }
}

# Synopsis: Push NuGet package.
task pushNuGet nuget, {
	if (!($NuGetApiKey = property NuGetApiKey '')) { $NuGetApiKey = Read-Host NuGetApiKey }
	exec { nuget push "ib.$Version.nupkg" -Source nuget.org -ApiKey $NuGetApiKey }
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
