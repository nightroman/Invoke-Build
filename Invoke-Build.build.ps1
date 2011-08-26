
<#
.Synopsis
	The build script for Invoke-Build itself.
#>

Set-StrictMode -Version 2

# Copy Invoke-Build.ps1 from its working location where it is normally modified.
task Update-Script {
	Copy-Item (Get-Command Invoke-Build.ps1).Definition .\Invoke-Build.ps1
}

# Take $script:Version string from Invoke-Build.ps1
task Version {
	$text = [System.IO.File]::ReadAllText("$BuildRoot\Invoke-Build.ps1")
	assert ($text -match '\s*Invoke-Build\s+(v\d+\.\d+\.\d+(\.\w+)?)\s+')
	$script:Version = $matches[1]
}

# Test Demo tests
task Test-Demo {
	Invoke-Build . Demo\.build.ps1
}

# Make the archive.
task Zip {
	exec { robocopy . z\Invoke-Build /mir /xd z .git /xf Invoke-Build.build.ps1 *.zip } (0..3)
	Push-Location z
	exec { & 7z a ..\Invoke-Build.$script:Version.zip Invoke-Build }
	Pop-Location
	Remove-Item z -Force -Recurse
}

# Run all checks and make a new archive.
task . Test-Demo, Update-Script, Version, Zip
