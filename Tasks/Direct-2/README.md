# Directly invokable build scripts (variant 2)

Build scripts are normally invoked by the engine `Invoke-Build`, not directly.
If this is inconvenient then decorate a script to make it directly invokable.
Variant 1 is described here: [Direct](../Direct), with scripts either invoked
directly or by `Invoke-Build`.

Another way, variant 2, is defining build tasks in a script like this:

```powershell
[CmdletBinding()]
param(
    [string[]]$Tasks
)

Invoke-Build $Tasks {
    task build {
        ...
    }
    task clean {
        ...
    }
    ...
}
```

Such scripts cannot be invoked by `Invoke-Build`, they are not composed as
build scripts. They are normal PowerShell scripts but they have tasks and
work similar to build scripts.

See the example script [Build.ps1](Build.ps1) and comments, try some calls:

```powershell
# run all tasks (because $Tasks default is set to '*')
./Build.ps1

# run with parameters
./Build.ps1 -Param1 testing

# run specified tasks
./Build.ps1 ScriptParameters, ScriptVariables

# show task descriptions
./Build.ps1 ?
```
