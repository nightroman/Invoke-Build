
# Invoke-Build Release Notes

## v5.0.0

Allow empty lines between synopsis comments and tasks, [#111](https://github.com/nightroman/Invoke-Build/issues/111).

Remove actions on dot-sourcing, [#112](https://github.com/nightroman/Invoke-Build/issues/112).

Retire obsolete features:

- `(job TaskName -Safe)` - instead, use `?TaskName` [#105](https://github.com/nightroman/Invoke-Build/issues/105)
- `use VisualStudio` - not used much, not designed for VS 2017

## v4.2.0

Preserve attributes of build script parameters, [#109](https://github.com/nightroman/Invoke-Build/issues/109).

Amend exit codes on `-Safe` in cmd: 1 on argument errors, 0 otherwise.

## v4.1.2

Add ability to use MSBuild from Visual Studio Preview, #107.

Avoid trailing `\r` in task synopses extracted from block comments.

Amend the role of `Done` in custom tasks. It is always called and works
as `finally` for a task. Handlers check for `$Task.Error` if it matters.

## v4.1.1

Improve `Result` on invalid arguments

- Ensure `Result`'s variable or hashtable `Value` entry is always created.
- Fail with a proper error if `Result` is not a string or hashtable.
- On invalid calls ensure at least a surrogate result `Error`.

Amend `Build-Parallel`

- Better errors on invalid builds parameters.
- Do not count incomplete build results.

Tidy up help.

## v4.1.0

- Improve syntax and usability of safe references. #105
    - Introduce `?TaskName` instead of deprecated `(job TaskName -Safe)`.
    - Support `?TaskName` in the parameter `-Task` of `Invoke-Build`.
- Redesign error output.
    - Improve for VSCode, AppVeyor, and redirection. #106
    - If a task fails in `If`, add it to the list of invoked tasks.

## v4.0.2

`Build-Checkpoint` should fail if not supported `WhatIf` is specified.

## v4.0.1

- Support colored output in AppVeyor, [#103](https://github.com/nightroman/Invoke-Build/issues/103).
- Deprecate `use VisualStudio`.

## v4.0.0

New command `Build-Checkpoint` replaces `Invoke-Build -Checkpoint`. If you use
persistent builds then change the command and parameters, see #101.

New command `Build-Parallel` replaces `Invoke-Builds` (mind "s"). If you use
parallel builds then simply rename the command, see #100.

## v3.7.2

Normalize, test, and make `$BuildRoot` constant after loading tasks (#95).

## v3.7.1

*Invoke-Builds* (parallel builds)

- Add `FailHard`, it tells to abort builds if any build fails.
- Redesign the script without using runspace pools.
- Avoid some duplicated info in output.

## v3.7.0

Package the module files together with scripts. As a result, the script package
may be used as the module, too. This change does not affect the module package.

Retire `Get-BuildVersion`. Use `(Get-Module InvokeBuild).Version` instead.
In theory, this change is breaking but it seems the function was not used.
The standard module version is used from now on.

## v3.6.5

Fix resuming of persistent builds after failures in task `-If` (#90).

## v3.6.4

Support version suffix x86 in `use` and `Resolve-MSBuild` (#85).

## v3.6.3

Resolve MSBuild 15 to ../amd64/MSBuild.exe on x64 (#84).

## v3.6.2

Warn about always skipped double references (#82).

## v3.6.1

- Fix #80, lost `Task` in the collected errors.
- Fix potential PS v6-beta.3 issues in *ib.cmd*.

## v3.6.0

Support script block as `File` (#78).

## v3.5.3

Improved product selection logic in `Resolve-MSBuild` (#77).
If you use the module `VSSetup` make sure it is not too old.
It should support `-Product *`.

## v3.5.2

- Avoid some `property` limitations (#75).
- Use `&` in `exec`, it looks safer.
- Tweak help.

## v3.5.1

- Remove redundant information from safe errors.
- Remove retired "Parameters" from reserved.

## v3.5.0

- New block `Set-BuildHeader` for writing custom task headers.
- New function `Get-BuildSynopsis`, e.g. for `Set-BuildHeader`.

See *repo/Tasks/Header* for examples of `Set-BuildHeader` and `Get-BuildSynopsis`.

## v3.4.0

New command `requires`, the alias of `Test-BuildAsset` (#73).

## v3.3.11

Rework engine variables to reduce noise on debugging (#72).

## v3.3.10

- Add exported aliases to .psd1, work around #71.
- Fix leaked variable on dot-sourcing Invoke-Build.

## v3.3.9

Fix incremental tasks on Mono (#69).

## v3.3.8

- Write messages about redefined tasks, resolve #68.
- Fix unexpected output on some debugging cases.

## v3.3.7

Improve errors on tasks check failures (#67).

## v3.3.6

Retire obsolete events defined as functions, see #66.

## v3.3.5

Use less cryptic names for internal functions (#63).

## v3.3.4

Adjust `property` behaviour to PowerShell and MSBuild (#60):

- get the session variable value if it is not $null or ''
- get the environment value if it is not $null or ''
- get the specified default if it is not $null
- throw an error

## v3.3.3

`Resolve-MSBuild` supports the *BuildTools* installation (#57).

## v3.3.2

Improve info on typical mistakes:

- missing comma in job lists
- unexpected build output
- dangling script blocks

## v3.3.1

Improve errors on invalid script syntax (#56).

## v3.3.0

New *Resolve-MSBuild.ps1* for finding MSBuild 2.0-15.0, specified or the latest.
It may be used directly. Build scripts use it via the alias `Resolve-MSBuild`.
NuGet and PSGallery packages include this script.

The old way `use <version> MSBuild` is supported and works with all versions.
But the new script is used internally, *Invoke-Build.ps1* alone is not enough.

## v3.2.4

Fix #54, `exec` should use `$global:LastExitCode`.

## v3.2.3

Use `exit /B` in *ib.cmd* (#52).

## v3.2.2

- Incremental tasks print some more info (#49)
- Outputs block receives piped Inputs (#50)

## v3.2.1

Module help tweaks.

## v3.2.0

`use`: The conventional path `VisualStudio\<version>` is resolved via the
registry to the Visual Studio tools directory (`devenv`, `mstest`, `tf`).

## v3.1.0

Event blocks instead of functions, see #36.

## v3.0.2

Use `exit 0` on success (#34).

## v3.0.1

Invoke-Build is cross-platform with PowerShell v6.0.0-alpha.

## v3.0.0

Build script parameters are specified as Invoke-Build dynamic parameters.
The parameter `Parameters` was removed. This change is breaking in some
cases, see [#29](https://github.com/nightroman/Invoke-Build/issues/29).

Avoided cryptic errors on invoking scripts with invalid syntax and on resuming
builds with an invalid checkpoint file.

## v2 releases

Previous release notes: [V2 Release Notes](https://github.com/nightroman/Invoke-Build/wiki/V2-Release-Notes)
