
Invoke-Build - Orchestrate Builds in PowerShell
===============================================

*Invoke-Build.ps1* is a standalone *Windows PowerShell* script used to invoke
tasks from build scripts.

Ideas come from the [psake](https://github.com/JamesKovacs/psake) module and
other build tools. This script provides an easy to use and yet robust engine.

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
