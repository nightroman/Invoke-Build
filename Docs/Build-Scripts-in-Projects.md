# Build Scripts in Projects

## FarNet build hierarchy (C++, C#)

The build system where `Invoke-Build` and `MSBuild` work together and call each
other. `MSBuild` usually calls `Invoke-Build` from post build events.

See [Building FarNet Showcase](Building-FarNet-Showcase.md)

## Invoke-Build, Helps (PowerShell scripts)

- [Invoke-Build/1.build.ps1](https://github.com/nightroman/Invoke-Build/blob/main/1.build.ps1)
- [Helps/1.build.ps1](https://github.com/nightroman/Helps/blob/main/1.build.ps1)

These scripts are for pure PowerShell script projects.
The following tasks are automated:

- Clean the project directory
- Run tests and compare results with expected
- Build the help file (PowerShell MAML format)
- Convert markdown files to HTML for packages
- Create packages

## SplitPipeline, Mdbc (C#, PowerShell modules)

- [SplitPipeline/1.build.ps1](https://github.com/nightroman/SplitPipeline/blob/main/1.build.ps1)
- [Mdbc/1.build.ps1](https://github.com/nightroman/Mdbc/blob/main/1.build.ps1)

These scripts are examples of mixed build tools: Invoke-Build and MSBuild work
together and call each other. See how the configuration parameter is passed in
both directions.

The task *Build* calls MSBuild in order to build the C# project:

```powershell
exec { MSBuild Src\Mdbc.csproj /t:Build /p:Configuration=$Configuration }
```

The task *PostBuild* is called by MSBuild as the post-build event, it copies
the just built module and its satellite files to one of the PowerShell module
directories, so that it is ready to use/debug after the build. The post-build
command line is:

```text
PowerShell.exe -NoProfile Invoke-Build PostBuild $(ProjectDir)\..\.build.ps1 -Configuration $(ConfigurationName)
```

Or even simpler with one of the [ib commands](https://github.com/nightroman/Invoke-Build/tree/main/ib#readme):

```text
ib PostBuild $(ProjectDir)\..\.build.ps1 -Configuration $(ConfigurationName)
```

Other tasks are typical: clean, test, build and test help, create packages.
Both projects use Invoke-Build for testing, each test is represented by a task
in a test build script.

## PowerShellTraps

- [PowerShellTraps/1.build.ps1](https://github.com/nightroman/PowerShellTraps/blob/main/1.build.ps1)

This project is a collection of PowerShell issues described by markdown files,
demo scripts, and test scripts. There is nothing to "build" here. The build
script is for testing, generating the index, and other routine tasks.

## PowerShell/PSReadLine

- [PSReadline.build.ps1](https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine.build.ps1)

A bash inspired readline implementation for PowerShell.

## PowerShell/vscode-powershell

- [vscode-powershell.build.ps1](https://github.com/PowerShell/vscode-powershell/blob/main/vscode-powershell.build.ps1)

PowerShell extension for Visual Studio Code.

## PowerShell/PowerShellEditorServices

- [PowerShellEditorServices.build.ps1](https://github.com/PowerShell/PowerShellEditorServices/blob/main/PowerShellEditorServices.build.ps1)

A common platform for PowerShell development support in any editor or application.

## Microsoft/PSRule

- [pipeline.build.ps1](https://github.com/microsoft/PSRule/blob/main/pipeline.build.ps1)

Validate infrastructure as code (IaC) and objects using PowerShell rules.

## Badgerati/Pode

- [pode.build.ps1](https://github.com/Badgerati/Pode/blob/develop/pode.build.ps1)

PowerShell web framework for creating REST APIs, Web Sites, and TCP/SMTP servers.

## AtlassianPS/JiraPS

- [JiraPS.build.ps1](https://github.com/AtlassianPS/JiraPS/blob/master/JiraPS.build.ps1)

PowerShell module to interact with Atlassian JIRA.

## red-gate build scripts

Some red-gate projects use Invoke-Build scripts:

- [build-script-template/build.ps1](https://github.com/red-gate/build-script-template/blob/master/.build/build.ps1)
- [XmlDoc2CmdletDoc/build.ps1](https://github.com/red-gate/XmlDoc2CmdletDoc/blob/master/.build/build.ps1)

## Format PowerShell Code Module

- [zloeber/FormatPowershellCode/.build.ps1](https://github.com/zloeber/FormatPowershellCode/blob/master/.build.ps1)

It is one of the most evolved Invoke-Build scripts.
It puts together a lot of typical project tasks with complex relations.

## MathieuBuisson/PSCodeHealth

- [PSCodeHealth.build.ps1](https://github.com/MathieuBuisson/PSCodeHealth/blob/master/PSCodeHealth.build.ps1)

PowerShell module gathering PowerShell code quality and maintainability metrics.
