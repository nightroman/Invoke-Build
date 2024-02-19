# Build script with Invoke-Build bootstrapping

In addition to being directly invokable, see [Direct](../Direct), build scripts
may automatically check for the availability of the command `Invoke-Build` and
install its module when needed

```powershell
param(
    [Parameter(Position=0)]
    [string[]]$Tasks,
    #... other script parameters
)

# bootstrap
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
    $ErrorActionPreference = 1
    if (!(Get-Command Invoke-Build -ErrorAction 0)) {
        Write-Host 'Installing module InvokeBuild...'
        Install-Module InvokeBuild -Scope CurrentUser -Force
        Import-Module InvokeBuild
    }
    return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

# the usual build script
task ...
```

See [Project.build.ps1](Project.build.ps1) for the working example.

See [Direct](../Direct) for some more details about direct calls.
