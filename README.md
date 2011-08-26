
Invoke-Build - Orchestrate Builds in PowerShell
===============================================

*Invoke-Build.ps1* is a standalone *Windows PowerShell* script used to invoke
tasks from build scripts.

Ideas come from the [psake](https://github.com/JamesKovacs/psake) module and
other build tools. This script provides a lightweight and yet robust engine.

*Invoke-Build* is specifically designed for multiple calls in the same session.
It never changes environment variables and the system path. It does not leave
any variables, functions, aliases after its calls, successful or not. It also
restores the current location. Caveat: called tasks can make such changes.

Several *Invoke-Build* builds can work simultaneously in the same session: as
nested calls and as parallel calls from background jobs or separate workspaces.

## Quick Start

**Step 1:**
Copy *Invoke-Build.ps1* to one of the system path directories. As a result, the
script can be called from any *PowerShell* code simply as `Invoke-Build`.

**Step 2:**
Set the current location to the *Invoke-Build\Demo* directory:

    Set-Location <your location>/Invoke-Build/Demo

**Step 3:**
Take a look at the tasks of the default *.build.ps1* build script there:

    Invoke-Build ?

It shows the tasks from this script and imported from `*.tasks.ps1` scripts.

**Step 4:**
Invoke the default (`.`) task from the default script (it tests *Invoke-Build*):

    Invoke-Build

You should see the build process output (*Invoke-Build* testing progress).

This is it. The script is installed and invokes build scenarios.

## Next Steps

Take a look at the main help:

    help Invoke-Build -Full

And function help, for example `Add-Task`:

    . Invoke-Build
    help Add-Task -Full

Explore existing build scripts with many typical use cases, problem cases, and
tutorial comments:

* *Invoke-Build.build.ps1* - the build script of this project;
* *Demo\.build.ps1* - the default script which calls all the tests;
* *Demo\Xyz.build.ps1* - use and problem cases grouped by categories.
