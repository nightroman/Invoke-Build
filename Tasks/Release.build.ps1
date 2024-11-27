<#
.Synopsis
	Steps to release Invoke-Build.

.Example
	> Invoke-Build . Release.build.ps1
	Start or resume persistent release steps.
#>

param(
	# persistent data
	$NuGetApiKey,
	$PSGalleryApiKey
)

$BuildRoot = '..'
Set-Alias ask Confirm-Build
Set-StrictMode -Version Latest

# Synopsis: It should be the main branch with no changes.
task status -if {ask} {
	assert ('main' -ceq (exec { git branch --show-current })) 'Please checkout main.'
	assert ($null -ceq (exec { git status --short })) 'Please commit changes.'
}

# Synopsis: Run Invoke-Build tests.
task test_IB -if {ask} test_ib_tool, {
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
task push_NuGet -if {ask} NuGetApiKey, {
	Invoke-Build pushNuGet
}

# Synopsis: Push the InvokeBuild module.
task push_PSGallery -if {ask} PSGalleryApiKey, {
	Invoke-Build pushPSGallery
}

# Synopsis: Push the ib package.
task push_ib_tool -if {ask} {
	Invoke-Build pushNuGet ib/ib.build.ps1
}

# Synopsis: Push and tag commits.
task push_release -if {ask} {
	Invoke-Build pushRelease
}

# Synopsis: Finish and browse package pages.
task clean_and_browse -if {ask} {
	Invoke-Build clean
	Start-Process https://www.powershellgallery.com/packages/InvokeBuild
	Start-Process https://www.nuget.org/packages/Invoke-Build/
	Start-Process https://www.nuget.org/packages/ib/
}

# Synopsis: Run all tasks with checkpoints.
task . -if {'.' -eq $BuildTask} {
	Build-Checkpoint -Auto $HOME\z.releaseInvokeBuild.clixml @{Task='*'; File=$BuildFile}
}
