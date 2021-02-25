# Invoke-Build Release Notes

## v5.7.2

Add the `ErrorMessage` parameter to `exec`, #178.

## v5.7.1

Inherit build headers and footers from parent builds.

## v5.7.0

Add the switch `Echo` to `exec`.

## v5.6.5

`Resolve-MSBuild` `Get-MSBuild15Guess` - stop search as soon as items found.

## v5.6.4

Tweak use of dynamic parameters.

## v5.6.3

Fixed potential issues with tasks and parameters named `Count`, `Keys`, `Values`, #173.

Created [Invoke-Build.template](https://github.com/nightroman/Invoke-Build.template)

## v5.6.2

Fail on adding tasks after loading build scripts, #171.

## v5.6.1

Add `InvocationInfo` to `Write-Warning` records and use in post build text.

*New-VSCodeTask.ps1* 1.3.1 - suppress echo and reuse messages in terminal.

## v5.6.0

Changed the default script resolution rule, see #166.

This change is potentially breaking but the chances are low.

## v5.5.11

Support PowerShell doc comment format for task synopsis #165

## v5.5.10

`Invoke-Build **` includes hidden test files.

## v5.5.9

Add `ib.sh` to the package, #162.

## v5.5.8

Add the workaround notes to `exec` help.

## v5.5.7

Add version to Invoke-Build.ps1 header comment.

**New-VSCodeTask.ps1**

- merges custom *.vscode/tasks-merge.json* with generated
- new parameter `Merge` specifies the custom merge path
- new parameter `Shell` specifies the custom shell path
- new parameter `WhereTask` filters build tasks

## v5.5.6

`Show-TaskHelp.ps1` - process `Inputs` and `Outputs` as well as `If` and `Jobs`.

## v5.5.5

Add parameter `MinimumVersion` to `Resolve-MSBuild` #154

## v5.5.4

Fix sorting by product in `Resolve-MSBuild` #153

## v5.5.3

Do not make script parameters named, fix #152

## v5.5.2

Add the switch `Preserve` to `Build-Checkpoint` #150

## v5.5.1

`Resolve-MSBuild` - allow some spaces in versions #148

## v5.5.0

Support MSBuild 16.0 of VS 2019, #146.

## v5.4.6

Support `remove -Verbose`, #147.

## v5.4.5

Amend help about `Write-Build`, #144.

## v5.4.4

Fix wrong task info in warning records, #142.

## v5.4.3

Save checkpoints after each task and before the first, #140.

Tools

- New *Build-JustTask.ps1* invokes tasks without references.
- *Show-BuildGraph.ps1* uses the latest viz.js, see #139.

## v5.4.2

Tiny internal tweak for *Show-BuildGraph.ps1*, #137

*Show-BuildGraph.ps1*, see #136:

- Show conditional tasks as diamonds.
- Show job numbers only on edges.

## v5.4.1

Add help for `Set-BuildHeader`, `Set-BuildFooter`.

## v5.4.0

- Add `Set-BuildFooter` in addition to `Set-BuildHeader`, #125
- Update the sample `Tasks/Header`, use custom footers, too.
- Tweak `remove` for more useful error location info.

## v5.3.0

Add the robust helper `remove`, the alternative to `Remove-Item`, see [#123](https://github.com/nightroman/Invoke-Build/issues/123)

Tools

- *New-VSCodeTask.ps1* 1.1.6 - Confirm removal of not generated file.

## v5.2.1

- New switch `Latest` of `Resolve-MSBuild`, #122

## v5.2.0

- **New:** Alternative syntax of task parameters, kind of inline splatting, [#119](https://github.com/nightroman/Invoke-Build/issues/119)
- Add "missing output" message to incremental task processing, [#120](https://github.com/nightroman/Invoke-Build/issues/120)

Tools

- *Invoke-TaskFromVSCode.ps1* should save the file on invoking, [#118](https://github.com/nightroman/Invoke-Build/issues/118)
- Improve *Invoke-TaskFromVSCode.ps1* error info in some cases
- Support `viz.js` in *Show-BuildGraph.ps1*

## v5.1.1

- `Show-TaskHelp` - switches are shown after other parameters.
- Optimized calls of `Show-TaskHelp` from `Invoke-Build`.

## v5.1.0

New internal tool, [#117](https://github.com/nightroman/Invoke-Build/issues/117)

- The new tool *Show-TaskHelp.ps1* is included to packages.
- `Invoke-Build ... -WhatIf` uses the new `Show-TaskHelp`.

New external tool, [#116](https://github.com/nightroman/Invoke-Build/issues/116)

- *Show-BuildDgml.ps1* generates build graphs as DGML for Visual Studio.

## v5.0.1

Tidy up some check failure errors, #115

Convert `FormatTaskName` by `Convert-psake`, #114

## v5.0.0

Allow empty lines between synopsis comments and tasks, #111.

Remove actions on dot-sourcing, #112.

Retire obsolete features:

- `(job TaskName -Safe)` - instead, use `?TaskName`, see #105.
- `use VisualStudio` - not used much, not designed for VS 2017

## v4.2.0

Preserve attributes of build script parameters, #109.

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
