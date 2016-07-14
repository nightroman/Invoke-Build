
<img src="https://raw.githubusercontent.com/nightroman/Invoke-Build/master/ib.png" align="right"/>
[![NuGet](https://buildstats.info/nuget/Invoke-Build)](https://www.nuget.org/packages/Invoke-Build)

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

Invoke-Build can invoke the current task from a build script being composed in
ISE and VSCode, see *Invoke-TaskFromISE.ps1* and *Invoke-TaskFromVSCode.ps1*.

Invoke-Build can be used as the task runner in VSCode with tasks maintained in
a PowerShell build script instead of *tasks.json*, see *New-VSCodeTask.ps1*.

## The package

The standalone script *Invoke-Build.ps1* is enough for invoking build scripts.
It can be downloaded directly from the repository and used alone right away.
The package also includes helper scripts and the generated help file:

* *Invoke-Build.ps1* - invokes build scripts, this is the build engine
* *Invoke-Builds.ps1* - invokes parallel builds using the engine
* *Invoke-Build-Help.xml* - external content for Get-Help
* *ib.cmd* - Invoke-Build helper for cmd.exe

Extra tools, see PSGallery and the repository:

* *Invoke-Build.ArgumentCompleters.ps1* - completers for v5 native, TabExpansionPlusPlus, TabExpansion2.ps1
* *Invoke-TaskFromISE.ps1* - invokes a task from a build script opened in ISE
* *Invoke-TaskFromVSCode.ps1* - invokes a task from a build script opened in VSCode
* *New-VSCodeTask.ps1* - generates VSCode tasks bound to build script tasks

And some more tools, see the repository:

* *Convert-psake.ps1* - converts psake build scripts
* *Show-BuildTree.ps1* - shows task trees as text
* *Show-BuildGraph.ps1* - shows task trees by Graphviz

## Install as module

Invoke-Build is distributed as the module [InvokeBuild](https://www.powershellgallery.com/packages/InvokeBuild).
In PowerShell 5.0 or with PowerShellGet you can install it by this command

    Install-Module InvokeBuild

The module provides commands `Invoke-Build` and `Invoke-Builds`.
Import the module in order to make them available:

    Import-Module InvokeBuild

You can also call the module scripts directly. Consider to include the module
directory to the path. In this scenario you do not have to import the module.

## Install as scripts

Invoke-Build is also distributed as the NuGet package [Invoke-Build](https://www.nuget.org/packages/Invoke-Build).

If you use [scoop](https://github.com/lukesampson/scoop) then invoke

    scoop install invoke-build

and you are done, scripts are downloaded and their directory is added to the
path. You may need to start a new PowerShell session with the updated path.

Otherwise download the directory *"Invoke-Build"* to the current location by
this PowerShell command:

    Invoke-Expression "& {$((New-Object Net.WebClient).DownloadString('https://github.com/nightroman/PowerShelf/raw/master/Save-NuGetTool.ps1'))} Invoke-Build"

Consider to include the directory with scripts to the path so that script paths
may be omitted in commands.

With *cmd.exe* use the helper *ib.cmd*. For similar experience in interactive
PowerShell use an alias `ib` defined in a PowerShell profile

    Set-Alias ib <path>\Invoke-Build.ps1

`<path>\` may be omitted if the script is in the path.

## Getting help

If you are using the module then import it at first. If you are using scripts
then make sure *Invoke-Build-Help.xml* from the package is in the same
directory as *Invoke-Build.ps1*. Then invoke

    help Invoke-Build -full

In order to get help for commands, dot-source `Invoke-Build`:

    . Invoke-Build

This imports commands and makes their help available:

    help task -full

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

Questions, suggestions, and issues are welcome at
[Google Group](https://groups.google.com/forum/#!forum/invoke-build) and
[Project Issues](https://github.com/nightroman/Invoke-Build/issues).
Or just hit me up on Twitter [@romkuzmin](https://twitter.com/romkuzmin)

## Credits

- The project was inspired by [*psake*](https://github.com/psake/psake), see [Comparison with psake](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-psake).
- Some concepts came from [*MSBuild*](https://github.com/Microsoft/msbuild), see [Comparison with MSBuild](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-MSBuild).
