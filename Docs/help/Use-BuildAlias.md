# Use-BuildAlias

```text
(use) Sets framework or directory tool aliases.
```

## Syntax

```text
Use-BuildAlias [-Path] String [[-Name] String[]]
```

## Description

```text
Scripts use its alias 'use'. Invoke-Build does not change the system path
in order to make framework tools available by names. This is not suitable
for using mixed framework tools (in different tasks, scripts, parallel
builds). Instead, this function is used for setting tool aliases in the
scope where it is called.

This command may be used in the script scope to make aliases for all tasks.
But it can be called from tasks in order to use more task specific tools.
```

## Parameters

```text
-Path
    Specifies the tools directory.
    
    If it is * or it starts with digits followed by a dot then the MSBuild
    path is resolved using the package script Resolve-MSBuild.ps1. Build
    scripts may invoke it directly by the provided alias Resolve-MSBuild.
    The optional suffix x86 tells to use 32-bit MSBuild.
    
        For just MSBuild use Resolve-MSBuild instead:
    
            Set-Alias MSBuild (Resolve-MSBuild ...)
            MSBuild ...
    
        or
    
            $MSBuild = Resolve-MSBuild ...
            & $MSBuild ...
    
    If it is like Framework* then it is assumed to be a path relative to
    Microsoft.NET in the Windows directory.
    
    Otherwise it is a full or relative literal path of any directory.
    
    Examples: *, 4.0, Framework\v4.0.30319, .\Tools
    
    Required?                    true
    Position?                    0
```

```text
-Name
    Specifies the tool names. They become aliases in the current scope.
    If it is a build script then the aliases are created for all tasks.
    If it is a task then the aliases are available just for this task.
    
    Required?                    false
    Position?                    1
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Use .NET 4.0 tools MSBuild, csc, ngen. Then call MSBuild.

use 4.0 MSBuild, csc, ngen
exec { MSBuild Some.csproj /t:Build /p:Configuration=Release }
```

## Links

```text
Invoke-BuildExec
Resolve-MSBuild
```
