
Build Automation in PowerShell
==============================

## Introduction

Invoke-Build is a build automation tool which invokes tasks defined in a
PowerShell script. Tasks are pieces of code with optional relations.
Concepts are similar to psake and MSBuild.

The engine is carefully designed for multiple calls: sequential, nested, and
even parallel. Each call maintains its data in its scope. It does not change
itself anything global including the environment.

Long running or interactive workflows with expected interruptions can be
automated with persistent builds which allow resuming after interruptions.

## The package

The standalone script *Invoke-Build.ps1* is enough for invoking build scripts.
Other files and tools are for built-in help, parallel builds, graphs, and etc.

* *Invoke-Build.ps1* invokes build scripts, this is the build engine
* *Invoke-Builds.ps1* invokes parallel builds using the engine
* *Invoke-Build-Help.xml* is external content for Get-Help
* *Invoke-TaskFromISE.ps1* invokes a task from ISE
* *Show-BuildTree.ps1* shows task trees as text
* *Show-BuildGraph.ps1* shows task trees by Graphviz
* *TabExpansionProfile.Invoke-Build.ps1* - completers

## How it works

The engine builds a sequence of tasks defined in a build script by `task`
statements which provide task names, script blocks, references, conditions,
inputs and outputs. The tasks are checked for issues like missing or cyclic
references. Then the specified tasks are invoked together with other tasks
referenced by them recursively. Why is this needed at all? See
[Concepts](https://github.com/nightroman/Invoke-Build/wiki/Concepts).

## Installation

Invoke-Build is distributed as the NuGet package [Invoke-Build](https://www.nuget.org/packages/Invoke-Build).
Download it to the current location as the directory *"Invoke-Build"* by this PowerShell command:

    iex (New-Object Net.WebClient).DownloadString('https://raw.github.com/nightroman/Invoke-Build/master/Download.ps1')

Alternatively, download it by NuGet tools or [directly](http://nuget.org/api/v2/package/Invoke-Build).
In the latter case rename the package to *".zip"* and unzip. Use the package
subdirectory *"tools"*.

Copy *Invoke-Build.ps1*, *Invoke-Build-Help.xml*, and optionally other scripts
to a directory in the path. As a result, the engine is called from PowerShell
as `Invoke-Build` and help for `Get-Help` is available.

## Getting help

To get help for *Invoke-Build.ps1* make sure *Invoke-Build-Help.xml* is in the
same directory and invoke this command:

    help Invoke-Build -full

In order to get help for functions, at first dot-source Invoke-Build:

    . Invoke-Build

The above command shows function names and makes their help available:

    help Add-BuildTask -full

## Online resources

- [Script Tutorial](https://github.com/nightroman/Invoke-Build/wiki/Script-Tutorial)
: Take a look in order to get familiar with scripts.
- [Project Wiki](https://github.com/nightroman/Invoke-Build/wiki)
: Detailed tutorials, helpers, notes, and etc.
- [Examples](https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-in-Projects)
: Build scripts used in various projects.
- [Tasks](https://github.com/nightroman/Invoke-Build/tree/master/Tasks)
: Custom tasks.

## Credits

The project is inspired by
[*psake*](https://github.com/psake/psake)
and some concepts come from
[*MSBuild*](http://en.wikipedia.org/wiki/Msbuild).
