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
        Install-Module InvokeBuild -Scope CurrentUser -Force -Verbose; Import-Module InvokeBuild
    }
    return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

# the usual build script
task ...
```

See [Project.build.ps1](Project.build.ps1) for the example.

The above bootstrap block does not require `InvokeBuild` module or its version.
The `Invoke-Build` command may be a script `Invoke-Build.ps1` in the path or an
alias pointing to the exact location `<path>/Invoke-Build.ps1`.

The next bootstrap block requires `InvokeBuild` module with `MinimumVersion`.
You may use `RequiredVersion` instead in order to pin the exact version.

```powershell
# bootstrap
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
    $ErrorActionPreference=1
    try { Import-Module InvokeBuild -MinimumVersion 5.14.20 }
    catch { Install-Module InvokeBuild -Scope CurrentUser -Force -Verbose; Import-Module InvokeBuild }
    return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}
```

Finally, the simplest bootstrap block may just install the module and do nothing else:

```powershell
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
    return Install-Module InvokeBuild -Scope CurrentUser -Force
}
```

Or it may install several modules including `InvokeBuild`:

```powershell
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
    return Install-Module InvokeBuild, PSRest, FarNet.ScottPlot -Scope CurrentUser -Force
}
```

In this way on a clean machine users first run the script directly in order to
install `InvokeBuild` and others. Then they use the command `Invoke-Build`.
