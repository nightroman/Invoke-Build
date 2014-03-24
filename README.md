
Invoke-Build - PowerShell Task Scripting
========================================

## Introduction

Invoke-Build invokes specified tasks defined in a PowerShell script.
This process is called build. Tasks are pieces of code with optional
relations. Concepts are similar to MSBuild and psake.

The engine is carefully designed for multiple calls: sequential, nested, and
even parallel. Each call maintains its data in its scope. It does not change
itself anything global including the environment.

Long running or interactive processes with expected interruptions can be
automated with persistent builds which allow resuming after interruptions.

## The Package

The standalone script *Invoke-Build.ps1* is enough for invoking build scripts.
Other files and tools are for built-in help, parallel builds, graphs, and etc.

* *Invoke-Build.ps1* invokes build scripts, this is the build engine
* *Invoke-Builds.ps1* invokes parallel builds using the engine
* *Invoke-Build-Help.xml* is external content for Get-Help
* *Build.ps1* is the helper designed for command lines
* *Show-BuildGraph.ps1* makes and shows task graphs
* *TabExpansionProfile.Invoke-Build.ps1* - completers

## How It Works

The engine builds a sequence of tasks defined in a build script by `task`
statements which provide task names, script blocks, references, conditions,
inputs and outputs. The tasks are checked for issues like missing or cyclic
references. Then the specified tasks are invoked together with other tasks
referenced by them recursively.

[More...](https://github.com/nightroman/Invoke-Build/wiki/How-Build-Works)

## Installation

Invoke-Build is distributed as the NuGet package [Invoke-Build](https://www.nuget.org/packages/Invoke-Build).
Download it to the current location as the directory *"Invoke-Build"* by this PowerShell command:

    Invoke-Expression (New-Object Net.WebClient).DownloadString('https://raw.github.com/nightroman/Invoke-Build/master/Download.ps1')

Alternatively, download it by NuGet tools or [directly](http://nuget.org/api/v2/package/Invoke-Build).
In the latter case rename the package to *".zip"* and unzip. Use the package
subdirectory *"tools"*.

Copy *Invoke-Build.ps1*, *Invoke-Build-Help.xml*, and optionally other scripts
to a directory in the path. As a result, the engine can be called from any
PowerShell code as `Invoke-Build` and `Get-Help` should work.

## Getting Help

To get help for *Invoke-Build.ps1* make sure *Invoke-Build-Help.xml* is in the
same directory and invoke this command:

    help Invoke-Build -full

In order to get help for functions, at first dot-source Invoke-Build:

    . Invoke-Build

The above command shows function names and makes their help available:

    help Add-BuildTask -full

## Online Resources

- [Script Tutorial](https://github.com/nightroman/Invoke-Build/wiki/Script-Tutorial)
: Take a look in order to get familiar with scripts.
- [Project's Wiki](https://github.com/nightroman/Invoke-Build/wiki)
: Full online tutorial, tools, and tips and tricks.
- [Examples](https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-in-Projects)
: Build scripts used in various projects.
- [Demo](https://github.com/nightroman/Invoke-Build/tree/master/Demo)
: Tests implemented as build scripts.

## Credits

The project is inspired by
[*psake*](https://github.com/psake/psake)
and some concepts come from
[*MSBuild*](http://en.wikipedia.org/wiki/Msbuild).
