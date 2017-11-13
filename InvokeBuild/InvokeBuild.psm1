
Set-Alias -Name Build-Checkpoint -Value (Join-Path $PSScriptRoot Build-Checkpoint.ps1)
Set-Alias -Name Build-Parallel -Value (Join-Path $PSScriptRoot Build-Parallel.ps1)
Set-Alias -Name Invoke-Build -Value (Join-Path $PSScriptRoot Invoke-Build.ps1)
Export-ModuleMember -Alias Build-Checkpoint, Build-Parallel, Invoke-Build
