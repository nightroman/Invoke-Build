# Special Variables

The build engine defines the following variables for scripts:
`$WhatIf`, `$OriginalLocation`, `$BuildRoot`, `$BuildFile`, `$BuildTask`, `$Task`, `$Job`
and variables `${*...}` for internal use.

Scripts should not create or change such variables or use for parameters.
Only the variable `$BuildRoot` may be changed by scripts in special cases.

The variable `$_` may be defined by the engine and visible. Scripts may use it
as their own, that is assign at first and then use. They should not assume
anything about incoming values except documented cases.

## $WhatIf

It is the parameter `WhatIf` of `Invoke-Build`. It may be used in the script
scope in order to skip some actions. It is not used in other code, because it
is not invoked when `WhatIf` is true.

`$WhatIf` is true in the following cases:

- `Invoke-Build` is invoked with the switch `WhatIf`.
- `Invoke-Build` is invoked with the special task `?` or `??`.

## $OriginalLocation

It is the current location path before the build.
This location is set current again after the build.

## $BuildRoot

It is the full path of the build script directory, by default.
Build scripts may alter it on loading in special cases.
For example:

- It is not suitable to keep a build script in a directory where it builds.
- A build script is designed to work for several or variable directories.

Example:

```powershell
param(
    # Custom build root, still the original $BuildRoot by default.
    $BuildRoot = $BuildRoot
)

# Alter the build root.
if (<something>) {
    $BuildRoot = ...
}

# Tasks are called with the current location set to $BuildRoot,
# either the default, or set by the parameter, or the altered.

task ...
```

It is fine to specify a path relative to the current location, the original or
changed by the script. Immediately after loading, `$BuildRoot` is resolved to
the full path with respect to the current location, tested, and made constant.
The latter means that `$BuildRoot` cannot be changed during the build.

Example:

```powershell
# change the location to the parent directory and adjust the build root
Set-Location ..
$BuildRoot = '.'

# tasks work with the new root resolved to full and maintained current
task ShowRoot {
    # these two should be the same:
    $BuildRoot
    (Get-Location).Path
}
```

## $BuildFile

It is the full path of the build script.

## $BuildTask

It is the list of initial tasks, the `Invoke-Build` parameter `Task`, either
the original or resolved by the engine.

## $Task

It is the current task being processed. It is available for script blocks
`If`, `Inputs`, `Outputs`, `Jobs`, `Enter-BuildTask`, `Exit-BuildTask`,
`Enter-BuildJob`, `Exit-BuildJob`, `Set-BuildHeader`, `Set-BuildFooter`.

These properties are available for reading:

- `Name` - task name, `[string]`
- `Started` - start time, `[DateTime]`
- In `Exit-BuildTask` only:
    - `Error` - task error, if any
    - `Elapsed` - task duration, `[TimeSpan]`

## $Job

It is the current action job being processed, the script block. It is available
for script blocks `Jobs`, `Enter-BuildJob`, `Exit-BuildJob`, `Set-BuildHeader`,
`Set-BuildFooter`.

See [#185](https://github.com/nightroman/Invoke-Build/issues/185) for a use case.

## Variables and functions `*...`

Variables and functions `*...` are used internally. For technical reasons some
of them are visible to scripts. Scripts should not use such names, existing or
not, or make assumptions about existing.
