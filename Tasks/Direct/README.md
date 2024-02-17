# Directly invokable build scripts

Build scripts are normally invoked by the engine `Invoke-Build`, not directly.
If this is inconvenient then decorate a script to make it directly invokable.
Add `Tasks` as the first parameter and the command redirecting the call:

```powershell
param(
    [Parameter(Position=0)]
    [string[]]$Tasks,
    #... other script parameters
)

# call the build engine with this script and return
if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
    return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

# the usual build script
task ...
```

As a result, you can invoke this script either directly:

```
<script> <tasks> [<parameters>]
```

or using the build engine:

```
Invoke-Build <tasks> <script> [<parameters>]
```

If the script name is like `*.build.ps1` and the current location is the script
directory or subdirectory then you may omit the script:

```
Invoke-Build <tasks> [<parameters>]
```

Note that `Invoke-Build` parameters are not available on direct calls, i.e. you
cannot specify `Safe`, `Summary`, `WhatIf`, etc. When they are needed use the
usual call by `Invoke-Build`.

See the script [my.build.ps1](my.build.ps1) for a working example.

## Bootstrap InvokeBuild

Directly invokable scripts may automatically install `InvokeBuild` when needed.

See examples:

- [08-bootstrap/tea.build.ps1](../01-step-by-step-tutorial/08-bootstrap/tea.build.ps1) - straightforward bootstrapping
- [Paket/Project.build.ps1](../Paket/Project.build.ps1) - some custom bootstrapping

## Notes

Consider making the parameter `Tasks` positional (`[Parameter(Position=0)]`) and keeping other parameters named.
This maintains similarity of parameters used by direct invocation and by `Invoke-Build`:
tasks are specified first, unnamed, then other parameters, all named.

Also, `Parameter` implies `CmdletBinding`, so we may omit `CmdletBinding` if it was used.
`Parameter` or `CmdletBinding` is recommended for parameter checks on direct invocations.
