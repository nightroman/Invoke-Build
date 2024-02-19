# Build script with automatic bootstrapping

The sample script *Project.build.ps1* shows how to use automatic bootstrapping.
The script is designed as directly invokable by PowerShell and it does not
require `Invoke-Build` installed. `Invoke-Build` is restored using `paket`,
locally.

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
    - Files generated or restored by `paket`.

These directories are usually added to `.gitignore`.

## Steps from scratch

Create the dotnet tool manifest *.config/dotnet-tools.json*:

    dotnet new tool-manifest

Install paket and add to the manifest:

    dotnet tool install paket

Create the paket file *paket.dependencies*:

    dotnet paket init

Add this line to *paket.dependencies*:

    nuget Invoke-Build storage: packages

Use the build script like *Project.build.ps1*.
