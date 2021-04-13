<#
.Synopsis
	Build script, https://github.com/nightroman/Invoke-Build
#>

param(
	[ValidateSet('Debug', 'Release')]
	[string]$Configuration = 'Release'
)

# Synopsis: Remove files.
task clean {
	remove bin, obj, z, content, ../z, ../README.htm
}

# Synopsis: Set $script:Version.
task Version {
	$r = switch -Regex -File ../Release-Notes.md {'##\s+v(\d+\.\d+\.\d+)' {$Matches[1]; break}}
	($script:Version = "$r.0")
}

# Synopsis: Set $script:Version.
task content -If (!(test-path content)) {
	Invoke-Build module ..\.build.ps1
	exec { robocopy ..\z\InvokeBuild content\InvokeBuild } (0..3)
}

# Synopsis: Make NuGet package.
task pack version, content, {
	exec { dotnet pack -c $Configuration -p:VersionPrefix=$Version -o z }
}

# Synopsis: Install the tool from package.
task install {
	exec { dotnet tool install --add-source z -g ib }
}

# Synopsis: Uninstall the tool.
task uninstall {
	dotnet tool uninstall -g ib
}

# Synopsis: Default task.
task . uninstall, pack, install, clean
