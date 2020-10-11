# Build script with automatic bootstrapping

The sample script *Project.build.ps1* shows how to use automatic bootstrapping.
The script is designed as directly invokable by PowerShell and it does not
require `Invoke-Build` installed. `Invoke-Build` is restored using `paket`.

The `paket` tool is used as one possible way of getting packages. Instead or in
addition, we could use `PSDepend`, `NuGet.exe`, `Install-Module`, etc.

Such a script is designed for scenarios like:

1. Get a project (clone a repository).
1. Invoke *Project.build.ps1* with required tasks and parameters.

## Directories and files

**The files before bootstrapping**

- *.config/dotnet-tools.json*
    - dotnet tool manifest, with `paket` in this sample.
- *paket.dependencies*
    - Project dependencies for `paket` including `Invoke-Build`.
      `Invoke-Build` is restored locally in *packages*.
- *Project.build.ps1*
    - Build script designed for direct calls and bootstrapping.
      It also contains the usual tasks required by the project.
- *paket.lock*
    - Lock file generated on `paket install`. It is recommended for source
      control if the project is potentially sensitive to package versions.
      NB In this sample, it is not included but created on bootstrapping.

**Extra files after bootstrapping**

- *packages*
    - Packages restored by `paket` and stored locally.
    In this sample, it is `Invoke-Build`.
- *paket-files*
    - Files generated or restored by `paket.

These directories are usually added to `.gitignore`.

## How to get PowerShell modules by paket

Module entries in *paket.dependencies* should normally use PSGallery source.
Module packages should be downloaded to *packages* (`storage: packages`).
The build script should be designed to import modules from *packages*.

This looks like a ceremony but it has some advantages. This scenario does not
pollute the usual PowerShell module directories and avoids possible module
version issues.

## How to customize package/module management

If `paket` and its *paket.dependencies* is not enough, e.g. you want to install
modules by `Install-Module`, then look at the "bootstrapping" block in
*Project.build.ps1* and add required checks and commands.

For example, just for the `InvokeBuild` module bootstrapping instead of `paket`
we could use this trivial PowerShell code:

```powershell
if (!(Get-Module InvokeBuild -ListAvailable)) {
    Install-Module InvokeBuild
    Import-Module InvokeBuild
    #... other stuff
}
```

## Steps from scratch

To create the dotnet tool manifest *.config/dotnet-tools.json*, invoke:

    dotnet new tool-manifest

To install paket and add its record to the manifest, invoke:

    dotnet tool install paket

To create the paket file *paket.dependencies*, invoke:

    dotnet paket init

Add Invoke-Build line to *paket.dependencies*:

    nuget Invoke-Build storage: packages

Add the sample build script *Project.build.ps1*.
