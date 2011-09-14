
Invoke-Build - Build Automation in PowerShell
=============================================

This script provides an easy to use and robust build engine with build scripts
written in [*PowerShell*](http://en.wikipedia.org/wiki/Powershell) and concepts
similar to [*MSBuild*](http://en.wikipedia.org/wiki/Msbuild) and
[*psake*](https://github.com/psake/psake).

Build scripts are *PowerShell* scripts that define tasks. Tasks consist of jobs
(references to other tasks and own scripts), conditions (Boolean expressions or
scripts), and inputs and outputs for incremental and partial incremental builds
(path lists or equivalent scripts).

Build scripts may have one of two forms: *classic* scripts are called by
`Invoke-Build`, *master* scripts dot-source `Invoke-Build` and `Start-Build`
themselves. Classic scripts are slightly easier to compose. Master scripts are
easier to use, sometimes significantly, especially with many parameters.

*Invoke-Build* is specifically designed for multiple calls in the same session.
It never changes environment variables and the system path. It does not leave
any variables, functions, aliases after its calls, successful or not. It also
restores the current location. Caveat: build tasks can make such changes.

Simultaneous *Invoke-Build* calls in the same session work without conflicts:
both nested calls and parallel builds called from background jobs or separate
workspaces.

## Comparison with MSBuild

*Invoke-Build* PowerShell scripts and *MSBuild* XML scripts are quite
different. But the concepts of these build tools are almost the same:

    MSBuild                      Invoke-Build
    -------                      ------------
    Default build script         A single *.build.ps1 or .build.ps1
    InitialTargets               Whatever build scripts invoke
    DefaultTargets               The "." task is the default
    Import                       Dot-source or invoke
    Target                       Task
    Condition                    -If
    Inputs, Outputs              -Inputs, -Outputs
    DependsOnTargets             -Jobs, referenced task names
    Tasks                        -Jobs, PowerShell script blocks
    AfterTargets, BeforeTargets  -After, -Before

[More...](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-MSBuild)

## Quick Start

**Step 1:**
Copy *Invoke-Build.ps1* to one of the system path directories. As a result, the
script can be called from any *PowerShell* code simply as `Invoke-Build`.

**Step 2:**
Set the current location to the *Demo* directory:

    Set-Location <path>/Demo

**Step 3:**
Take a look at the tasks of the default *.build.ps1* build script there:

    Invoke-Build ?

It shows the tasks from this script and imported from `*.tasks.ps1` scripts.

**Step 4:**
Invoke the default (`.`) task from the default script (it tests the engine):

    Invoke-Build

You should see the build process output (*Invoke-Build* testing progress).

This is it. The script is installed and invokes build scripts.

## Next Steps

Take a look at this help:

    help Invoke-Build -full

And then at functions help, for example `Add-BuildTask` (`task`):

    . Invoke-Build
    help task -full

Explore existing build scripts with many typical use cases, problem cases, and
tutorial comments:

* *Build.ps1* - the build script of this project;
* *Demo/.build.ps1* - the default script which calls all the tests;
* *Demo/Xyz.build.ps1* - use and problem cases grouped by categories.
