
Set-Alias -Name Invoke-Build -Value (Join-Path $PSScriptRoot Invoke-Build.ps1)
Set-Alias -Name Invoke-Builds -Value (Join-Path $PSScriptRoot Invoke-Builds.ps1)
Export-ModuleMember -Alias Invoke-Build, Invoke-Builds
