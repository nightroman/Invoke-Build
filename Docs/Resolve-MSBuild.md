# Resolve-MSBuild

[Resolve-MSBuild.ps1]: https://github.com/nightroman/Invoke-Build/blob/main/Resolve-MSBuild.ps1
[VSSetup]: https://github.com/Microsoft/vssetup.powershell
[Resolve-MSBuild]: https://www.powershellgallery.com/packages/Resolve-MSBuild

For many years MSBuild locations could be discovered using the registry,
namely, for versions 2.0 - 14.0. Starting with MSBuild 15.0 (Visual Studio
2017) this is not the case.

For PowerShell scripts Microsoft recommends the module [VSSetup]. It is handy
but it does not give MSBuild paths directly. The proper code for this is not
obvious and may depend on versions.

The script [Resolve-MSBuild.ps1] finds the specified or latest version of
MSBuild. All known MSBuild versions are covered. The script is supposed to
evolve and adapt to new versions.

Build scripts may use `Resolve-MSBuild.ps1` either directly by the provided
alias `Resolve-MSBuild` or by the older command `use <version> MSBuild`.

## Examples

Get various MSBuild paths:

```powershell
# get the latest MSBuild, one of 2.0 - 16.0+
Resolve-MSBuild *

# get MSBuild with the specified major version
Resolve-MSBuild 15.0
Resolve-MSBuild 4.0

# get the latest 32-bit MSBuild and assert that its version is at least 16.3
Resolve-MSBuild x86 -MinimumVersion 16.3
```

In build scripts, consider using `Resolve-MSBuild` in the beginning and setting
an alias for all tasks:

```powershell
Set-Alias MSBuild (Resolve-MSBuild)

task Build {
    exec { MSBuild MyProject.csproj /t:Build }
}

task Clean {
    exec { MSBuild MyProject.csproj /t:Clean }
}
```

Alternatively, use a variable with the resolved path and invoke it using `&`:

```powershell
$MSBuild = Resolve-MSBuild

task Build {
    exec { & $MSBuild MyProject.csproj /t:Build }
}

task Clean {
    exec { & $MSBuild MyProject.csproj /t:Clean }
}
```

If not many tasks use MSBuild or they need different versions,
use `Resolve-MSBuild` with required parameters in task actions:

```powershell
task Build {
    $MSBuild = Resolve-MSBuild 15.0x86
    exec { & $MSBuild MyProject.csproj /t:Build }
}
```
