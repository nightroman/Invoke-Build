<#
.Synopsis
	Steps to release Invoke-Build.

.Description
	Example of "Run all tasks".
	Example of "Confirm tasks".
#>

param(
	$NuGetApiKey,
	$PSGalleryApiKey
)

$BuildRoot = '../..'
$Ask = @{If = {Confirm-Build}}
Set-StrictMode -Version Latest

# Synopsis: It should be the main branch with no changes.
task status @Ask {
	assert ('main' -ceq (exec { git branch --show-current })) 'Please checkout main.'
	assert (!(exec { git status --short })) 'Please commit changes.'
}

# Synopsis: Run Invoke-Build tests.
task test_IB @Ask test_ib_tool, {
	Invoke-Build
}

# Synopsis: Test the ib dotnet tool.
task test_ib_tool {
	Invoke-Build . ib/ib.build.ps1
}

# Synopsis: Get and keep the API key.
task NuGetApiKey {
	$script:NuGetApiKey = Read-Host NuGetApiKey
}

# Synopsis: Get and keep the API key.
task PSGalleryApiKey {
	$script:PSGalleryApiKey = Read-Host PSGalleryApiKey
}

# Synopsis: Push the Invoke-Build package.
task push_NuGet @Ask NuGetApiKey, {
	Invoke-Build pushNuGet
}

# Synopsis: Push the InvokeBuild module.
task push_PSGallery @Ask PSGalleryApiKey, {
	Invoke-Build pushPSGallery
}

# Synopsis: Push the ib package.
task push_ib_tool @Ask {
	Invoke-Build pushNuGet ib/ib.build.ps1
}

# Synopsis: Push and tag commits.
task push_release @Ask {
	Invoke-Build pushRelease
}

# Synopsis: Finish and browse.
task clean_and_browse @Ask {
	Invoke-Build clean
	Start-Process https://www.powershellgallery.com/packages/InvokeBuild
}

# Synopsis: All tasks.
task . @(${*}.All.Keys)
