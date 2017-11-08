
## How to make build scripts invokable directly

Build scripts are normally invoked by the engine `Invoke-Build`, not directly.
If this is inconvenient then decorate a script to make it directly invokable.
Add `Tasks` as the first parameter and the command redirecting the call:

```powershell
    param(
        [Parameter(Position=0)]
        $Tasks,
        #... other script parameters
    )

    if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
        Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
        return
    }

    # The usual build script stuff
    task ...
```

As a result, you can invoke this script either using the standard way:

```
    Invoke-Build <tasks> <script> <parameters>
```

or directly

```
    <script> <tasks> <parameters>
```

Note that some Invoke-Build parameters are not available on direct calls, i.e.
`Safe`, `Summary`, `WhatIf`, etc. When they are needed just use the normal
invocation by the engine, this is easier than to support them on direct
calls (possible but not so neat).

See the script [build.ps1](build.ps1) for a working example.

See also the sample [Paket](../Paket) where a directly invokable build script
is designed for automatic bootstrapping with Invoke-Build downloaded as well.
