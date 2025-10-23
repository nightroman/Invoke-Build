# Build script with Invoke-Build bootstrapping

In addition to being directly invokable, see [Direct](../Direct), build scripts
may automatically check for the availability of the command `Invoke-Build` and
install its module when needed

```powershell
param(
    [Parameter(Position=0)]
    [string[]]$Tasks
)

# bootstrap
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
    $ErrorActionPreference=1
    if (!(Get-Command Invoke-Build -ErrorAction 0)) {
        Write-Host InvokeBuild...; Install-Module InvokeBuild -Scope CurrentUser -Force; Import-Module InvokeBuild
    }
    return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

# the usual build script
task ...
```

See [Project.build.ps1](Project.build.ps1) for the example.

The above bootstrap block does not require `InvokeBuild` module or its version.
`Invoke-Build` may be a script `Invoke-Build.ps1` in the path or a script alias
with full path `<path>/Invoke-Build.ps1`.

The below bootstrap block requires `InvokeBuild` module with the specified
minimum version. Use `RequiredVersion` instead of `MinimumVersion` in order
to pin the exact version.

```powershell
# bootstrap
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
    $ErrorActionPreference=1
    try { Import-Module InvokeBuild -MinimumVersion 5.14.20 }
    catch { Write-Host InvokeBuild...; Install-Module InvokeBuild -Scope CurrentUser -Force; Import-Module InvokeBuild }
    return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}
```
