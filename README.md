
[![NuGet](https://buildstats.info/nuget/Invoke-Build)](https://www.nuget.org/packages/Invoke-Build)
[![PSGallery](https://img.shields.io/powershellgallery/dt/InvokeBuild.svg)](https://www.powershellgallery.com/packages/InvokeBuild)
<img src="https://raw.githubusercontent.com/nightroman/Invoke-Build/master/ib.png" align="right"/>

## Build Automation in PowerShell

Invoke-Build is a build and test automation tool which invokes tasks defined in
PowerShell v2.0+ scripts. It is similar to psake but arguably easier to use and
more powerful. It is complete, bug free, well covered by tests.

In addition to basic task processing the engine supports

- Incremental tasks with effectively processed inputs and outputs.
- Persistent builds which can be resumed after interruptions.
- Parallel builds in separate workspaces with common stats.
- Batch invocation of tests composed as tasks.
- Ability to define new classes of tasks.

Invoke-Build v3.0.1+ is cross-platform with PowerShell v6.

Invoke-Build can be effectively used in VSCode and ISE.

Several *PowerShell Team* projects use Invoke-Build.

## The package

The package includes the engine, helpers, and the generated help:

* *Invoke-Build.ps1* - invokes build scripts, this is the build engine
* *Build-Checkpoint.ps1* - invokes persistent builds using the engine
* *Build-Parallel.ps1* - invokes parallel builds using the engine
* *Resolve-MSBuild.ps1* - finds the specified or latest MSBuild
* *Show-TaskHelp.ps1* - shows task help, used on WhatIf calls
* *InvokeBuild-Help.xml* - external content for Get-Help
* *ib.cmd*, *ib.sh* - cmd and bash helpers

Extra tools, see PSGallery and the repository:

* *Invoke-Build.ArgumentCompleters.ps1* - completers for v5 native, TabExpansionPlusPlus, TabExpansion2.ps1
* *Invoke-TaskFromVSCode.ps1* - invokes a task from a build script opened in VSCode
* *New-VSCodeTask.ps1* - generates VSCode tasks bound to build script tasks
* *Invoke-TaskFromISE.ps1* - invokes a task from a script opened in ISE

And some more tools, see the repository:

* *Build-JustTask.ps1* - invokes tasks without references
* *Convert-psake.ps1* - converts psake build scripts, see [wiki](https://github.com/nightroman/Invoke-Build/wiki/Convert~psake)
* *Show-BuildTree.ps1* - shows task trees as text
* *Show-BuildDgml.ps1* - shows task trees as DGML
* *Show-BuildGraph.ps1* - shows task trees by Graphviz

## Install as module

Invoke-Build is distributed as the module [InvokeBuild](https://www.powershellgallery.com/packages/InvokeBuild).
In PowerShell 5.0 or with PowerShellGet you can install it by this command

    Install-Module InvokeBuild

To install the module with Chocolatey, run the following command.
NOTE: This package is maintained by its owner, see package info.

    choco install invoke-build

Module commands: `Invoke-Build`, `Build-Checkpoint`, `Build-Parallel`.
Import the module in order to make them available:

    Import-Module InvokeBuild

You can also call the module scripts directly. Consider to include the module
directory to the path. In this scenario you do not have to import the module.

## Install as scripts

Invoke-Build is also distributed as the NuGet package [Invoke-Build](https://www.nuget.org/packages/Invoke-Build).
This package includes the module files, so it can be used as the module, too,
either copy it to the standard module folder or import its `InvokeBuild.psd1`.

If you use [scoop](https://github.com/lukesampson/scoop) then invoke

    scoop install invoke-build

and you are done, scripts are downloaded and their directory is added to the
path. You may need to start a new PowerShell session with the updated path.

Otherwise, download the package manually, rename it to zip, extract its *tools*
and rename to *InvokeBuild*. Consider to include this directory to the path so
that script paths may be omitted in commands. Or copy to the PowerShell module
directory in order to use as the module.

With *cmd.exe* use the helper *ib.cmd*. For similar experience in interactive
PowerShell use an alias `ib` defined in a PowerShell profile

    Set-Alias ib <path>\Invoke-Build.ps1

`<path>\` may be omitted if the script is in the path.

## Getting help

If you are using the module (see [#2899]) or the script is not in the path
then use the full path to *Invoke-Build.ps1* instead of *Invoke-Build* in
the below commands, see `(Get-Alias Invoke-Build).Definition`

[#2899]: https://github.com/PowerShell/PowerShell/issues/2899

In order to get help for the engine, invoke:

    help Invoke-Build -full

In order to get help for internal commands:

    . Invoke-Build
    help task -full
    help exec -full
    ...

## Online resources

- [Basic Concepts](https://github.com/nightroman/Invoke-Build/wiki/Concepts)
: Why build scripts may have advantages over normal scripts.
- [Script Tutorial](https://github.com/nightroman/Invoke-Build/wiki/Script-Tutorial)
: Take a look in order to get familiar with build scripts.
- [Project Wiki](https://github.com/nightroman/Invoke-Build/wiki)
: Detailed tutorials, helpers, notes, and etc.
- [Examples](https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-in-Projects)
: Build scripts used in various projects.
- [Tasks](https://github.com/nightroman/Invoke-Build/tree/master/Tasks)
: Samples, patterns, and various techniques.
- [Design Notes](https://github.com/nightroman/Invoke-Build/wiki/Design-Notes)
: Technical details for contributors.
- [Release Notes](https://github.com/nightroman/Invoke-Build/blob/master/Release-Notes.md)

Questions, suggestions, and reports are welcome as project issues.
Or just hit me up on Twitter [@romkuzmin](https://twitter.com/romkuzmin)

## Credits

- The project was inspired by [*psake*](https://github.com/psake/psake), see [Comparison with psake](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-psake).
- Some concepts came from [*MSBuild*](https://github.com/Microsoft/msbuild), see [Comparison with MSBuild](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-MSBuild).
