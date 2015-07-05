
## ![](https://raw.githubusercontent.com/nightroman/Invoke-Build/master/ib.png) Build Automation in PowerShell

Invoke-Build is a build and test automation tool which invokes tasks
defined in PowerShell scripts. It is similar to psake but arguably
easier to use and more powerful.

In addition to basic task processing the engine supports

- Incremental tasks with effectively processed inputs and outputs.
- Persistent builds which can be resumed after interruptions.
- Parallel builds as a part of another with common stats.
- Batch invocation of tests composed as tasks.
- Ability to define new classes of tasks.

## The package

The standalone script *Invoke-Build.ps1* is enough for invoking build scripts.
It can be downloaded directly from the repository and used alone right away.
The package also includes helper scripts and the generated help file:

* *Invoke-Build.ps1* - invokes build scripts, this is the build engine
* *Invoke-Builds.ps1* - invokes parallel builds using the engine
* *Invoke-Build-Help.xml* - external content for Get-Help
* *ib.cmd* - Invoke-Build helper for cmd.exe

Extra tools are available at the project repository:

* *Convert-psake.ps1* - converts psake build scripts
* *Invoke-TaskFromISE.ps1* - invokes a task from ISE
* *Show-BuildTree.ps1* - shows task trees as text
* *Show-BuildGraph.ps1* - shows task trees by Graphviz
* *TabExpansionProfile.Invoke-Build.ps1* - code completers

## Installation

Invoke-Build is distributed as the NuGet package [Invoke-Build](https://www.nuget.org/packages/Invoke-Build).
Download it to the current location as the directory *"Invoke-Build"* by this PowerShell command:

    iex (New-Object Net.WebClient).DownloadString('https://github.com/nightroman/Invoke-Build/raw/master/Download.ps1')

Alternatively, get it by NuGet tools or [download](http://nuget.org/api/v2/package/Invoke-Build).
In the latter case rename the package to *".zip"* and unzip. Use the package
subdirectory *"tools"*.

This is it, scripts are ready to use. Consider to include the directory with
scripts to the system path so that script paths may be omitted in commands.

With *cmd.exe* use the helper *ib.cmd*. For similar experience in interactive
PowerShell use an alias `ib` defined in a PowerShell profile

    Set-Alias ib <path>\Invoke-Build.ps1

`<path>\` may be omitted if the script is in the path.

## Getting help

Make sure *Invoke-Build-Help.xml* from the package is in the same directory as
*Invoke-Build.ps1* and invoke

    help Invoke-Build -full

In order to get help for commands, at first dot-source Invoke-Build:

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
[Google Discussion Group](https://groups.google.com/forum/#!forum/invoke-build) and
[Project Issues](https://github.com/nightroman/Invoke-Build/issues).
Or just hit me up on Twitter [@romkuzmin](https://twitter.com/romkuzmin)

## Credits

The project was inspired by [*psake*](https://github.com/psake/psake).
Some concepts come from [*MSBuild*](https://github.com/Microsoft/msbuild).
