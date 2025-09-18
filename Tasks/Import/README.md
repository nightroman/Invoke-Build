# How to share and import tasks

Tasks designed for sharing are normally defined in standard PowerShell scripts
with the recommended suffix *.tasks.ps1*. Then these scripts are dot-sourced
in build scripts.

This sample demonstrates:

- How to import tasks from several conventional task scripts.
- How to import tasks from a module which provides tasks.
- How to use `requires` in imported scripts.

The build script `1.build.ps1` imports tasks from external task scripts.

## Example 1. Import from conventional task scripts

Several task scripts are located in the directory *MyScript*. All found there
`*.tasks.ps1` are imported by dot-sourcing. In practice, where to get such
files and how to name them is up to authors.

Each sample `*.tasks.ps1` specifies assets of various types by `requires`.
Assets of different types may be specified in one command:

```powershell
requires -Variable ... -Environment ... -Path ...
```

## Example 2. Import from a module with tasks

The module *MyModule* exports some usual module stuff and also tasks. Due to
some known module scope features, tasks normally should not be defined in
*.psm1* files. Instead, follow these steps:

In a module, to export:

- Define tasks in a usual script file, e.g. *MyModule.tasks.ps1*.
- In the module *.psm1* define and export an alias to this script.

```powershell
Set-Alias MyModule.tasks $PSScriptRoot/MyModule.tasks.ps1
Export-ModuleMember -Alias MyModule.tasks
```

In a build script, to import:

- Import a module.
- Dot-source its task script using its alias.

```powershell
Import-Module MyModule
. MyModule.tasks
```

If the exact name `MyModule.tasks` is not known or there are several commands
then get them from the module by the pattern `*.tasks` and import in a loop:

```powershell
Import-Module MyModule
foreach($file in Get-Command *.tasks -Module MyModule) {. $file}
```

## See Also

- [Extends](../Extends)
