# Portable Build Scripts

It is possible and sometimes expected to have a copy of Invoke-Build tools kept
together with build scripts. This makes the build tool set portable, i.e. build
scripts may be invoked on any machine without Invoke-Build installed.

Another reason to keep a copy of Invoke-Build with scripts is use of multiple
build engine versions, potentially incompatible. Existing build scripts do not
have to be upgraded for a newer version, they may continue using the old copy.

Build scripts are already portable if they do not call `Invoke-Build.ps1`
(nested build) and the satellite scripts `Build-Parallel.ps1`,
`Resolve-MSBuild.ps1`, `Show-TaskHelp.ps1`.

Otherwise, build scripts should follow the rule: invoke the above scripts by
their aliases defined by the engine: `Invoke-Build`, `Build-Parallel`,
`Resolve-MSBuild`, `Show-TaskHelp`.

These aliases guarantee the correct scripts invoked, even if there are other
scripts with same names in the system path. Namely,

- `Invoke-Build` is the alias of the currently running engine `Invoke-Build.ps1`;
- `Build-Parallel` is the alias of `Build-Parallel.ps1` in the engine folder;
- etc.

Thus, nested calls of `Invoke-Build` from tasks invoke `Invoke-Build.ps1` which
is currently running (e.g. which is kept together with the scripts). Compare:
calls to `Invoke-Build.ps1`, i.e. with the extension, may fail because either
`Invoke-Build.ps1` is not in the system path or its version is incompatible.

Only top level commands may invoke builds as `Invoke-Build.ps1` (assuming it is
in the path) or `<some-path>/Invoke-Build.ps1` (assuming it is there).
