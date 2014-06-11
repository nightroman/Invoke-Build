
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

*Invoke-Build.ps1* is enough for invoking build scripts. Other files and tools
are for built-in help, parallel builds, task visualization, and etc.

* *Invoke-Build.ps1* - invokes build scripts, this is the build engine
* *Invoke-Builds.ps1* - invokes parallel builds using the engine
* *Invoke-Build-Help.xml* - external content for Get-Help

Extras

* *ib.cmd* - Invoke-Build helper for cmd.exe
* *Convert-psake.ps1* - converts psake build scripts
* *Invoke-TaskFromISE.ps1* - invokes a task from ISE
* *Show-BuildTree.ps1* - shows task trees as text
* *Show-BuildGraph.ps1* - shows task trees by Graphviz
* *TabExpansionProfile.Invoke-Build.ps1* - completers
* *Tasks* - sample custom tasks and demo scripts

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

Alternatively, get it by NuGet tools or [download](http://nuget.org/api/v2/package/Invoke-Build).
In the latter case rename the package to *".zip"* and unzip. Use the package
subdirectory *"tools"*.

This is it, scripts are ready to use. Consider to include the directory with
scripts to the system path so that script paths may be omitted in commands.

With *cmd.exe* use the helper *ib.cmd*. For similar experience in interactive
PowerShell use an alias `ib` defined in the PowerShell profile

    Set-Alias ib <path>\Invoke-Build.ps1

`<path>\` may be omitted if the script is in the system path.

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

Questions, suggestions, and issues are welcome at
[Google Discussion Group](https://groups.google.com/forum/#!forum/invoke-build) and
[Project Issues](https://github.com/nightroman/Invoke-Build/issues).
Or just hit me up on Twitter [@romkuzmin](https://twitter.com/romkuzmin)

## Credits

The project was inspired by [*psake*](https://github.com/psake/psake).
Some concepts come from [*MSBuild*](http://en.wikipedia.org/wiki/Msbuild).
