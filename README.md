
Invoke-Build.ps1 - Build Automation in PowerShell
=================================================

![MSBuild and Invoke-Build](https://github.com/downloads/nightroman/Invoke-Build/ProjectVsScript.png)

*Invoke-Build.ps1* is a [build automation](http://en.wikipedia.org/wiki/Build_automation)
tool implemented as a standalone PowerShell script. It invokes tasks defined in
PowerShell build scripts using a few domain-specific language (DSL) features.
Scripts and DSL features are similar to [*psake*](https://github.com/psake/psake).
Build flow and concepts are similar to [*MSBuild*](http://en.wikipedia.org/wiki/Msbuild).

The main DSL feature of build scripts is the `task`. Build tasks consist of jobs
(references to other tasks and own scripts), conditions (Boolean expressions or
script blocks), and inputs and outputs for incremental and partial incremental
builds (path lists or equivalent scripts).

*Invoke-Build* is carefully designed for multiple calls in the same PowerShell
session: sequential, nested, and even parallel in background jobs. It maintains
its state completely on the stack and never changes environment variables, the
system path, and the current process directory.

## Comparison with MSBuild

*Invoke-Build* PowerShell scripts and *MSBuild* XML scripts use different
syntax. But build flow, scripts structure, and concepts are very similar:

    MSBuild                      Invoke-Build
    -------                      ------------
    Default build script         A single *.build.ps1 or .build.ps1
    InitialTargets               Whatever a build script invokes
    DefaultTargets               The . or the first added task
    Properties                   Script/environment variables
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
Copy *Invoke-Build.ps1* and its help file *Invoke-Build.ps1-Help.xml* to one of
the system path directories. As a result, the script can be called from any
*PowerShell* code simply as `Invoke-Build`.

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

Take a look at help (make sure *Invoke-Build.ps1-Help.xml* is in the same
directory as *Invoke-Build.ps1*):

    help Invoke-Build -full

And then at functions help, for example, `Add-BuildTask` (`task`). Note that
*Invoke-Build* has to dot-sourced once for that.

    . Invoke-Build
    help task -full
    help property -full
    ...

Explore build scripts in the *Demo* directory included into the package. They
show many typical use cases, problem cases, and contain tutorial comments.

*Demo* scripts might be useful in order to get familiar with the concepts but
they are just tests, not real project build scripts. Take a look at the list of
build scripts in some projects in
[here](https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-in-Projects).

## See Also

* [How It Works](https://github.com/nightroman/Invoke-Build/wiki/How-It-Works)
* [Script Tutorial](https://github.com/nightroman/Invoke-Build/wiki/Script-Tutorial)
* [Incremental Tasks](https://github.com/nightroman/Invoke-Build/wiki/Incremental-Tasks)
* [Partial Incremental Tasks](https://github.com/nightroman/Invoke-Build/wiki/Partial-Incremental-Tasks)
* [Build Result Analysis](https://github.com/nightroman/Invoke-Build/wiki/Build-Result-Analysis)
* [Comparison with MSBuild](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-MSBuild)
* [Build Scripts in Projects](https://github.com/nightroman/Invoke-Build/wiki/Build-Scripts-in-Projects)
