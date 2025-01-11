# Directly invokable build scripts

See also [Direct-2](../Direct-2)

Build scripts are normally invoked by the engine `Invoke-Build`, not directly.
If this is inconvenient then decorate a script to make it directly invokable.
Add `Tasks` as the first parameter and the code block redirecting the call:

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

See [Project.build.ps1](Project.build.ps1) for the working example.

## Caveats

Directly invocable build scripts are handy but they have rules and limitations.

The rules are the extra parameter `$Tasks` and the code block "who calls me".
This code block must be placed immediately after the script parameter block.

Script parameters cannot use `Invoke-Build` features, e.g. `parameter` in
default parameter value expressions.

`Invoke-Build` parameters `Safe`, `Summary`, `WhatIf` are not available on
direct calls.

## Bootstrap

Directly invokable scripts may automatically install the `InvokeBuild` module.

See examples:

- [Bootstrap/Project.build.ps1](../Bootstrap/Project.build.ps1) - straightforward bootstrapping
- [Paket/Project.build.ps1](../Paket/Project.build.ps1) - some custom bootstrapping

## Notes

Consider making the parameter `Tasks` positional (`[Parameter(Position=0)]`) and keeping other parameters named.
This maintains similarity of parameters used by direct invocation and by `Invoke-Build`:
tasks are specified first, unnamed, then other parameters, all named.

Also, `Parameter` implies `CmdletBinding`, so we may omit `CmdletBinding` if it was used.
`Parameter` or `CmdletBinding` is recommended for parameter checks on direct invocations.
