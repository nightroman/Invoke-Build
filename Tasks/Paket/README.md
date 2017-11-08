
[paket]: https://fsprojects.github.io/Paket
[PSDepend]: https://github.com/RamblingCookieMonster/PSDepend

## Directly invokable build script with automatic bootstrapping

This sample shows how to add some automatic bootstrapping to a build script.
We use `paket` for getting packages. Instead or in addition, we could use
[PSDepend], `NuGet.exe`, `Install-Module`, etc.

After cloning the project, in a PowerShell prompt call

```powershell
Set-Location <project directory>
./Project.build.ps1 Build
```

Note that *Project.build.ps1* is called directly, not by Invoke-Build, because
at this point it may not exist. This command downloads the packages and calls
the local Invoke-Build with the specified task.

### Points of interest

- Packages are downloaded locally, nothing is installed or changed outside
  except the global package cache.
- If *paket.lock* is included then it ensures particular package versions.
  This is important for projects sensitive to package changes.
- `paket` does not add versions to downloaded package names.
  Build tasks and scripts may rely on relative paths to items in *packages*.
- *Project.build.ps1* is a build script for direct calls by PowerShell or by
  Invoke-Build. The first way calls `paket install` when needed and invokes
  local Invoke-Build. The second is for global Invoke-Build, it calls tasks
  as usual assuming already installed packages.

### The directory structure before bootstrapping

- *Project.build.ps1*
    - Build script decorated for direct calls and bootstrapping.
      It also contains normal build tasks required by the project.
- *paket.dependencies*
    - Project dependencies for `paket`. This file contains Invoke-Build
      needed for running tasks and other dependencies, none in this sample.
- *.gitignore*
    - Excludes downloaded packages and files from git.
- *.paket*
    - Package installer, quite small, if this matters.

### Extra files and directories after bootstrapping

- *packages*
- *paket-files*
    - Packages and files downloaded by `paket`.
      These directories should be added to `.gitignore`.
- *paket.lock*
    - Lock file generated on `paket install`. It is recommended for source
      control if the project is potentially sensitive to package versions.

### Is it possible to get PowerShell modules by paket?

Yes. But they are downloaded to *packages* and the build script should assume
and import modules from there. This ceremony has some advantages. It does not
pollute module directories and avoids module version collisions.

### Is it possible to customize package/module management?

If `paket` and its *paket.dependencies* is not enough, e.g. you want to install
modules by `Install-Module`, then look at the "install packages" block in
*Project.build.ps1* and add required checks and commands.

In fact, just for Invoke-Build bootstrapping instead of `paket` we can use
this trivial PowerShell code:

```powershell
if (!(Get-Module InvokeBuild -ListAvailable)) {
    Install-Module InvokeBuild
    Import-Module InvokeBuild
    #... other stuff
}
```

### Mind the primitive package readiness check

*Project.build.ps1* triggers `paket install` if it cannot find the expected
*Invoke-Build.ps1* in *packages*. This trivial approach is good enough for
bootstrapping but it is not suitable for package updates. Package updates
are performed by the included `paket`.

Alternatively, you may remove *packages* and bootstrap everything again. This
is not necessarily expensive because recently installed packages are normally
taken from the cache, not downloaded again.
