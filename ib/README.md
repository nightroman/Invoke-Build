# ib commands

## dotnet tool ib

[nuget.org/packages/ib](https://www.nuget.org/packages/ib/) provides Invoke-Build
as the dotnet tool `ib` which may be installed as global or local. It may be
used on any platform supporting PowerShell and dotnet.

Invoke-Build does not have to be installed separately, the tool contains it.
But with just the tool you may miss some PowerShell features like argument
completers, live error analysis, debugging, etc.

To install the global tool:

    dotnet tool install --global ib

To install the local tool:

    dotnet new tool-manifest # once on setting up a repo with tools
    dotnet tool install --local ib

### Usage

```
The following commands and options are supported:

- Show this help
  ib -h|--help

- Show command help
  ib -h|--help task|exec|assert|...

- Show Invoke-Build help
  ib -?
  ib /?

- Call Invoke-Build with arguments
  ib [--pwsh] [arguments]

    --pwsh
      On Windows tells to run by pwsh (the default is powershell).
      On other platforms pwsh is used and required in any case.
```

## shell script ib

Alternatively, you may use the following helper scripts:

- [ib.cmd](../ib.cmd)
- [ib.sh](../ib.sh)

Unlike with the tool `ib`, Invoke-Build has to be installed, either as the
module in a standard location or as scripts with the directory added to the
path.

## PowerShell alias ib

For similar experience in PowerShell interactive consoles you may add the alias
`ib` in your profile. Examples:

```powershell
# installed as module
Set-Alias ib Invoke-Build

# installed as scripts
Set-Alias ib .../Invoke-Build.ps1
```
