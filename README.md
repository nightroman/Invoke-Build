
[![PSGV](https://img.shields.io/powershellgallery/v/InvokeBuild)![PSGD](https://img.shields.io/powershellgallery/dt/InvokeBuild)](https://www.powershellgallery.com/packages/InvokeBuild)
[![NGV](https://img.shields.io/nuget/v/Invoke-Build)![NGD](https://img.shields.io/nuget/dt/Invoke-Build)](https://www.nuget.org/packages/Invoke-Build)
<img src="https://raw.githubusercontent.com/nightroman/Invoke-Build/main/ib.png" align="right"/>

## Build Automation in PowerShell

Invoke-Build is a build and test automation tool which invokes tasks defined in
PowerShell v3.0+ scripts. It is similar to psake but arguably easier to use and
more powerful. It is complete, bug free, well covered by tests.

In addition to basic task processing the engine supports

- Incremental tasks with effectively processed inputs and outputs.
- Persistent builds which can be resumed after interruptions.
- Parallel builds in separate workspaces with common stats.
- Batch invocation of tests composed as tasks.
- Ability to define new classes of tasks.

Invoke-Build v3.0.1+ is cross-platform with PowerShell Core.

Invoke-Build can be effectively used in VSCode and ISE.

Several *PowerShell Team* projects use Invoke-Build.

## The package

The package includes the engine, helpers, and help:

- [Invoke-Build.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Invoke-Build.ps1) - invokes build scripts, this is the build engine
- [Build-Checkpoint.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Build-Checkpoint.ps1) - invokes persistent builds using the engine
- [Build-Parallel.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Build-Parallel.ps1) - invokes parallel builds using the engine
- [Resolve-MSBuild.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Resolve-MSBuild.ps1) - finds the specified or latest MSBuild
- [Show-TaskHelp.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Show-TaskHelp.ps1) - shows task help, used on WhatIf calls
- `about_InvokeBuild.help.txt` - module help file
- `Help.xml` - content for Get-Help

Extra scripts, see PSGallery and the repository:

- [Invoke-Build.ArgumentCompleters](https://www.powershellgallery.com/packages/Invoke-Build.ArgumentCompleters) - completers for v5 native, TabExpansion2.ps1
- [Invoke-TaskFromVSCode](https://www.powershellgallery.com/packages/Invoke-TaskFromVSCode) - invokes a task from a build script opened in VSCode
- [Show-BuildGraph](https://www.powershellgallery.com/packages/Show-BuildGraph) - shows task graph by Graphviz Viz.js or dot
- [New-VSCodeTask](https://www.powershellgallery.com/packages/New-VSCodeTask) - generates VSCode tasks bound to build script tasks
- [Invoke-TaskFromISE](https://www.powershellgallery.com/packages/Invoke-TaskFromISE) - invokes a task from a script opened in ISE

And some more tools, see the repository:

- [ib.cmd](https://github.com/nightroman/Invoke-Build/blob/main/ib.cmd), [ib.sh](https://github.com/nightroman/Invoke-Build/blob/main/ib.sh) - cmd and bash helpers
- [Build-JustTask.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Build-JustTask.ps1) - invokes tasks without references
- [Convert-psake.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Convert-psake.ps1) - converts psake build scripts
- [Show-BuildTree.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Show-BuildTree.ps1) - shows task trees as text
- [Show-BuildDgml.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Show-BuildDgml.ps1) - shows task graph as DGML
- [Show-BuildMermaid.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Show-BuildMermaid.ps1) - shows task graph by Mermaid

## Install as module

Invoke-Build is published as PSGallery module [InvokeBuild](https://www.powershellgallery.com/packages/InvokeBuild).
You can install it by one of these commands:

    Install-Module InvokeBuild

To install the module with Chocolatey, run the following command:

    choco install invoke-build

NOTE: The Chocolatey package is maintained by its owner.

## Install as scripts

Invoke-Build is also published as [nuget.org/packages/Invoke-Build](https://www.nuget.org/packages/Invoke-Build).

If you use [scoop](https://github.com/lukesampson/scoop) then invoke:

    scoop install invoke-build

and you are done, scripts are downloaded and their directory is added to the
path. You may need to start a new PowerShell session with the updated path.

Otherwise, download the package manually, rename it to zip, extract its *tools*
and rename to *InvokeBuild*. Consider including this directory to the path for
invoking scripts by names. Or copy to any PowerShell module directory in order
to use it as module.

## Install as dotnet tool

[nuget.org/packages/ib](https://www.nuget.org/packages/ib) provides Invoke-Build
as the dotnet tool `ib` which may be installed as global or local.

To install the global tool:

    dotnet tool install --global ib

To install the local tool:

    dotnet new tool-manifest # once on setting up a repo with tools
    dotnet tool install --local ib

See [ib/README](https://github.com/nightroman/Invoke-Build/blob/main/ib/README.md) for more details about `ib` commands.

## Getting help

[#2899]: https://github.com/PowerShell/PowerShell/issues/2899

If you use the module (known issue [#2899]) or the script is not in the path,
use the full path `help .../Invoke-Build.ps1` instead of `help Invoke-Build`.

In order to get help for the engine, invoke:

    help Invoke-Build -full

In order to get help for internal commands:

    . Invoke-Build
    help task -full
    help exec -full
    ...

See also online [Invoke-Build Help](https://github.com/nightroman/Invoke-Build/blob/main/Docs/help/README.md)

## Online resources

- [Basic Concepts](https://github.com/nightroman/Invoke-Build/blob/main/Docs/Concepts.md) Why build scripts may have advantages over normal scripts.
- [Script Tutorial](https://github.com/nightroman/Invoke-Build/blob/main/Docs/Script-Tutorial.md) Take a look in order to get familiar with build scripts.
- [Step by Step Tutorial](https://github.com/nightroman/Invoke-Build/tree/main/Tasks/01-step-by-step-tutorial) From "Hello world" to featured scripts.
- [Invoke-Build.template](https://github.com/nightroman/Invoke-Build.template) Create scripts by `dotnet new ib`.
- [Examples](https://github.com/nightroman/Invoke-Build/blob/main/Docs/Build-Scripts-in-Projects.md) Build scripts used in various projects.
- [Tasks](https://github.com/nightroman/Invoke-Build/tree/main/Tasks) Samples, patterns, and various techniques.
- [Design Notes](https://github.com/nightroman/Invoke-Build/blob/main/Docs/Design-Notes.md) Technical details for contributors.
- [Invoke-Build Docs](https://github.com/nightroman/Invoke-Build/blob/main/Docs/README.md) Full documentation.
- [Invoke-Build Help](https://github.com/nightroman/Invoke-Build/blob/main/Docs/help/README.md) Commands help.
- [Release Notes](https://github.com/nightroman/Invoke-Build/blob/main/Release-Notes.md)

[discussions]: https://github.com/nightroman/Invoke-Build/discussions
[issues]: https://github.com/nightroman/Invoke-Build/issues

Questions, suggestions, and reports are welcome at [discussions] and [issues].

## Credits

- The project was inspired by [psake](https://github.com/psake/psake),
    see [Comparison with psake](https://github.com/nightroman/Invoke-Build/blob/main/Docs/Comparison-with-psake.md)
- Some concepts came from [MSBuild](https://github.com/Microsoft/msbuild),
    see [Comparison with MSBuild](https://github.com/nightroman/Invoke-Build/blob/main/Docs/Comparison-with-MSBuild.md)
