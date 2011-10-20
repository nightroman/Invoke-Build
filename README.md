
Invoke-Build.ps1 - Build Automation in PowerShell
=================================================

![Together](https://github.com/downloads/nightroman/Invoke-Build/Together.png)

## Introduction

Invoke-Build.ps1 is a build automation tool implemented as a standalone
PowerShell script. It invokes tasks defined in build scripts written in
PowerShell with a few domain-specific language features. Build flow and
concepts are similar to MSBuild. Scripts are similar to psake but look more
like usual due to standard PowerShell parameters and script scope variables.

Invoke-Build is carefully designed for multiple calls in the same PowerShell
session: sequential, nested, and even parallel. Every call maintains its state
completely on the stack. The engine does not change environment variables, the
path, and global variables and settings. This is all up to build scripts.

## What Does It Build?

All it builds is a sequence of script blocks defined in scripts by several
`task` statements with parameters which establish task names, script blocks,
dependencies, conditions, and inputs and outputs for incremental and partial
incremental tasks. Then this sequence of task scripts is invoked.

[More...](https://github.com/nightroman/Invoke-Build/wiki/How-Build-Works)

## Comparison with MSBuild

MSBuild is yet another build automation tool, part of the .NET Framework.
Invoke-Build is designed to be very similar. Of course, their scripts use
different languages (PowerShell and XML) and different built-in and external
tools. But build flow, script structure, and main concepts are almost the same.

    MSBuild                      Invoke-Build
    -------                      ------------
    Default build script         A single *.build.ps1 or .build.ps1
    InitialTargets               Whatever a build script invokes
    DefaultTargets               The . or the first added task
    Properties                   Script/environment variables
    Import                       Dot-source or invoke
    Target                       task
    Condition                    -If
    Inputs, Outputs              -Incremental or -Partial
    DependsOnTargets             -Jobs, referenced task names
    Tasks                        -Jobs, PowerShell script blocks
    AfterTargets, BeforeTargets  -After, -Before

[More...](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-MSBuild)

## Quick Start

**Step 1:**
An easy way to get and update the package is
[NuGet.exe Command Line](http://nuget.codeplex.com/releases):

    NuGet install Invoke-Build

Alternatively, manually download and unzip the latest package from
[Downloads](https://github.com/nightroman/Invoke-Build/downloads).

Copy *Invoke-Build.ps1* and its help *Invoke-Build.ps1-Help.xml* to the path.
As a result, the script can be called from any PowerShell code simply as
`Invoke-Build` and `Get-Help` should work.

If you use the sources, they do not include *Invoke-Build.ps1-Help.xml*, get it
with packages or build it using [Helps.ps1](https://github.com/nightroman/Helps).

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

    Build completed with errors. 139 tasks, 28 errors, 1 warnings, 00:00:12

This is it, Invoke-Build is ready to build scripts. If building existing scripts
is all that you need then you are done. Otherwise, in order to learn the basics
and create own scripts, read the
[Script Tutorial](https://github.com/nightroman/Invoke-Build/wiki/Script-Tutorial).

## Next Steps

Take a look at help (ensure *Invoke-Build.ps1-Help.xml* is in the same
directory as *Invoke-Build.ps1*):

    help Invoke-Build -full

And then at functions help, for example, `Add-BuildTask` (`task`). Note that
Invoke-Build has to be dot-sourced once.

    . Invoke-Build
    help task -full
    help property -full
    ...

Explore build scripts included into the package. With tutorial comments they
show typical use cases and cover issues and mistakes.

*Demo* scripts help to get familiar with the concepts but they are tests, not
real project build scripts. Some projects using build scripts are listed in
[here](https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-in-Projects).

## Credits

Invoke-Build is inspired by [*psake*](https://github.com/psake/psake), the
famous and probably the first build automation tool implemented in PowerShell.

Build concepts come from [*MSBuild*](http://en.wikipedia.org/wiki/Msbuild).
The goal was to make Invoke-Build similar as much as possible.

## See Also

[Invoke-Build wiki](https://github.com/nightroman/Invoke-Build/wiki) -
online tutorial, build scripts in projects, tips and tricks, ...

----
