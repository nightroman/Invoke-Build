
Invoke-Build - PowerShell Task Scripting
========================================

## Introduction

Invoke-Build introduces task based programming in PowerShell. It invokes tasks
from scripts written in PowerShell with domain-specific language. This process
is called build. Concepts are similar to MSBuild. Scripts are similar to psake.

Invoke-Build is carefully designed for multiple calls in the same PowerShell
session: sequential, nested, and even parallel (using *Invoke-Builds.ps1*).
Every call maintains its state completely on the stack. The engine does not
change the process environment or anything global in the PowerShell session.

Long running or interactive processes with expected interruptions can be
automated with persistent builds which allow resuming after interruptions.

## The Package

The standalone script *Invoke-Build.ps1* is enough for invoking build scripts.
Other tools and files are for parallel builds, built-in help, graphs, and etc.

* *Invoke-Build.ps1* invokes build scripts, this is the build engine
* *Invoke-Builds.ps1* invokes parallel builds using the engine
* *Invoke-Build-Help.xml* is external content for Get-Help
* *Build.ps1* is the wrapper with some more options
* *Show-BuildGraph.ps1* makes and shows task graphs
* *Demo* directory - scripts for learning and testing

## How Does It Work?

The engine builds a sequence of tasks defined in build scripts by `task`
statements which provide task names, references, conditions, inputs and
outputs, and script blocks. The tasks are checked for issues like missing or
cyclic references. Then the specified tasks and their references are invoked.

[More...](https://github.com/nightroman/Invoke-Build/wiki/How-Build-Works)

## Comparison with MSBuild

MSBuild is a build automation tool which is the part of the .NET Framework.
Invoke-Build is designed to be very similar. Of course, their scripts use
different languages (PowerShell and XML) and different built-in and external
tools. But build flow, script structure, and main concepts are almost the same.

[More...](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-MSBuild)

## Quick Start

**Step 1:**
Invoke-Build is distributed as a NuGet package. An easy way to get and update
it is [NuGet.exe Command Line](http://nuget.codeplex.com/releases):

    NuGet install Invoke-Build

This command checks for the latest available version, downloads, and unzips the
package to a directory named *Invoke-Build.(version)*. The scripts and other
files are located in its subdirectory *tools*.

Copy the script *Invoke-Build.ps1*, the help file *Invoke-Build-Help.xml*, and
optionally other scripts to one of the directories included in the system path
(`$env:PATH`). As a result, the script can be called from any PowerShell code
simply as `Invoke-Build` and `Get-Help` should work.

**Step 2:**
Set the current location to the *Demo* directory of the package:

    Set-Location <path>/Demo

**Step 3:**
Take a look at the tasks of the default *.build.ps1* build script there:

    Invoke-Build ?

It shows the tasks from this script and imported from `*.tasks.ps1` scripts.

**Step 4:**
Invoke the default task from the default script (it tests the engine):

    Invoke-Build

If the last output message starts with "Build completed" then ignore errors and
warnings, they are expected during this test. If it starts with "Build FAILED"
please submit an issue (tests sensitive to UI culture may fail, only en-US was
tested).

    Build completed with errors. 189 tasks, 38 errors, 1 warnings, 00:00:15

This is it, Invoke-Build is ready to build scripts. If building existing scripts
is all that you need then you are done. Otherwise, in order to learn the basics
and create own scripts, read the
[Script Tutorial](https://github.com/nightroman/Invoke-Build/wiki/Script-Tutorial).

## Next Steps

Read help for *Invoke-Build.ps1* (ensure *Invoke-Build-Help.xml* is in the same
directory):

    help Invoke-Build -full

Read help for functions. Note that Invoke-Build has to be dot-sourced for this:

    . Invoke-Build

The above command shows function names and makes their help available:

    help Add-BuildTask -full

Explore build scripts included into the package. With tutorial comments they
show typical use cases and cover issues and mistakes.

*Demo* scripts are good for getting familiar with the concepts but they are
tests, not real build scripts. Some build scripts used in projects listed in
[here](https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-in-Projects).

## Credits

Invoke-Build is inspired by [*psake*](https://github.com/psake/psake) and some
concepts come from [*MSBuild*](http://en.wikipedia.org/wiki/Msbuild).

## See Also

[Invoke-Build wiki](https://github.com/nightroman/Invoke-Build/wiki) -
Online tutorial, example scripts in projects, tips and tricks, ...
