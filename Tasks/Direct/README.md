## Directly invokable build scripts

Build scripts are normally invoked by the engine `Invoke-Build`, not directly.
If this is inconvenient then decorate a script to make it directly invokable.
Add `Tasks` as the first parameter and the command redirecting the call:

```powershell
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string[]]$Tasks,
    #... other script parameters
)

# call the build engine with this script and return
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
    Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
    return
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

Note that the attribute `CmdletBinding` is recommended, to avoid ignoring
misspelled or not supported parameters, e.g. mentioned `WhatIf` and etc.
and invoking with potentially unexpected results.

See the script [my.build.ps1](my.build.ps1) for a working example.

See also the sample [Paket](../Paket) where a directly invokable build script
is designed for automatic bootstrapping with `Invoke-Build` downloaded as well.
