# Invoke-Build Release Notes

[Issues](https://github.com/nightroman/Invoke-Build/issues) [Releases](https://github.com/nightroman/Invoke-Build/releases) [Discussions](https://github.com/nightroman/Invoke-Build/discussions)

## v5.14.23

`Resolve-MSBuild` - add more paths for VS 2026, #244

## v5.14.22

Fix `Resolve-MSBuild` regression, #242

## v5.14.21

`Resolve-MSBuild` - support v18, VS 2026.

## v5.14.20

Ignore progress in `Remove-BuildItem` (`remove`).

## v5.14.19

Wiki moved to /Docs, updated help links.

`Show-BuildGraph.ps1` - viz-3.17.0

## v5.14.18

Add `Write-Build` alias `print`, #240

## v5.14.17

Apply `Extends` prefixes to `After` and `Before` references, #239

## v5.14.16

`requires` (`Test-BuildAsset`) uses `ValidateNotNullOrEmpty` , #238\
*Potentially but unlikely breaking, see the issue.*

Removed undocumented alias `Show-TaskHelp`.\
Use `Invoke-Build -WhatIf` or `Show-TaskHelp.ps1`.\
*Breaking if the undocumented alias was used.*

Simplified `Show-BuildTree.ps1`, #236

Improved "Missing task" errors, #237

Added more details to `about_InvokeBuild.help.txt`.

## v5.14.15

Show jobs synopses on `-WhatIf`, #235

`Show-BuildGraph.ps1` - use viz-3.15.0 and its new `viz-global.js` replacing `viz-standalone.js`

`Show-BuildMermaid.ps1` - hide mermaid text on loading

## v5.14.14

Support "Extends" with and without prefixes used together, #234

Start creating GitHub releases, #230

## v5.14.13

Housekeeping. Put functions in order, exclude most of internals from loading on
dot-sourcing `Invoke-Build`, tweak satellite scripts.

`Get-BuildFile` is officially documented.

`Show-BuildGraph.ps1` uses viz-3.14.0.

## v5.14.12

`Build-Checkpoint`
- Support omitted or script `Checkpoint`

Amend pseudo task `*`
- Exclude the default dot-task `.`
- Exclude tasks from other scripts
- Update `Show-BuildTree.ps1` logic

Fixed
- Parameter values on loading extended scripts

## v5.14.11

Use `[ordered]` accelerator.

`Show-BuildGraph.ps1`
- New switch `Cluster` supporting `$Extends`
- See real example, [build graph with clusters](https://github.com/nightroman/Invoke-Build/blob/main/Docs/Show-Build-Graph.md#farnet)

## v5.14.10

Ensure "Extends" prefixes rules, #232

`Show-BuildGraph.ps1` - use viz-3.13.0

## v5.14.9

Update help, tidy up code.

## v5.14.8

Add build variable `$BuildRoots`, #231

## v5.14.7

Task help (`Invoke-Build ?`) columns order: `Name`, `Synopsis`, `Jobs`.\
(`Jobs` used to be the second, perhaps due to some old formatting issues.)

New demo case [Tasks/Steps](https://github.com/nightroman/Invoke-Build/tree/main/Tasks/Steps).

## v5.14.6

Do not rename dot-tasks on `Extends`.

## v5.14.5

Minor tweaks.

## v5.14.4

Support task prefixes on `Extends`, #229

## v5.14.3

Support common parameters on `Extends`, #228

## v5.14.2

- Amend `Extends` path resolution.
- Amend redefined task position.

## v5.14.1

`Invoke-Build -WhatIf` and `Show-TaskHelp` support `Extends`.

## v5.14.0

**New feature: Build script inheritance**\
*(Consider it as preview in v5.14.x)*

Build script parameters `Extends` with `ValidateScript` attributes tell to
dot-source scripts and replace `Extends` with inherited base parameters.

Documentation and examples of multilevel and multiple inheritance:\
<https://github.com/nightroman/Invoke-Build/tree/main/Tasks/Extends>

## v5.13.1

Add `property -Boolean`, #225

## v5.13.0

New helper `Get-BuildVersion`.

## v5.12.2

Disable ANSI rendering when called by MSBuild.

## v5.12.1

`Invoke-Build` parameter `File` accepts directory paths as well.
The usual build script resolution applies but without parents.

## v5.12.0

Stop supporting and testing PowerShell v2.0 (unlikely practical).

Fix `Use-BuildEnv` potential issues in PowerShell 7.5.

Fix `ib` dotnet tool similar potential issues.

`Show-BuildGraph.ps1` - use viz-3.11.0

## v5.11.3

`exec -Echo`: echo properties, #221

## v5.11.2

Like `ib.cmd`, the dotnet tool `ib` uses the environment variable `pwsh`.

`Show-BuildGraph.ps1` - use viz-3.5.0

## v5.11.1

`requires` / `Test-BuildAsset`
- improved errors on invalid null/empty arguments

## v5.11.0

`exec` / `Invoke-BuildExec`
- new switch `StdErr`, to get more useful error messages, #218
- `$LastExitCode` is set to 0 before invoking, to avoid subtleties

## v5.10.6

Fix cryptic errors on unknown parameters, #217

Minor tweaks, new demo Tasks/Repeat2, etc.

`Show-BuildGraph.ps1`
- available at PSGallery
- uses `Viz.js` by default and `dot` with `-Dot`
- shows node and edge tooltips (synopses, names)

`Show-BuildMermaid.ps1`
- uses `Mermaid` 10.8.0

## v5.10.5

`Resolve-MSBuild.ps1`: Tweak errors, do not wrap internal errors, #216

New script `Show-BuildMermaid.ps1` for viewing build task graphs.

## v5.10.4

Support verbose and information streams in `Build-Parallel`, #212

## v5.10.3

Add `ProgressAction` to common parameters, #210

## v5.10.2

Use global `$pwd`, #208

## v5.10.1

Make `Use-BuildEnv` parameters mandatory.

## v5.10.0

New helper function `Use-BuildEnv`.

## v5.9.12

Fix ANSI in PS Core 7.2.6, #204

## v5.9.11

- rename master to main, update links
- use `%pwsh%` in ib.cmd
- use `net6.0` in ib tool

## v5.9.10

Fix package version issue, #198.

## v5.9.9

Amend `Build-Checkpoint` for PS v2.

Retire deprecated alias `error`, use `Get-BuildError` instead.

## v5.9.8

Amend parameter sets of `Build-Checkpoint`.

## v5.9.7

New parameter `Path` of `requires` (`Test-BuildAsset`).

## v5.9.6

Amend output on task errors. #194

## v5.9.5

`Write-Build`: render lines separately, #193

## v5.9.4

Tweak getting variable expressions.

## v5.9.3

Amend `exec -echo` output, use `cd ...`.

Add `Release.build.ps1`.

## v5.9.2

Amend `exec -echo` for ANSI rendering, #192

## v5.9.1

With PowerShell 7.2+ and `$PSStyle.OutputRendering` ANSI, `Write-Build` uses
ANSI escape sequences. As far as `Write-Build` is used by the engine itself,
build/task headers/footers and build messages are rendered accordingly, for
example, colored in GitHub workflow terminals.

## v5.9.0

New switch `Auto` of `Build-Checkpoint`.

New build script helper `Confirm-Build`

- See *Tasks/Confirm* for `Confirm-Build` demo and notes
- *Tasks/Confirm* replaces its predecessor *Tasks/Ask*

The build variable `$Task` previously defined for tasks is also defined in the
script scope. It has the only property `Name` set to `$BuildFile`, the build
script path. Scripts should not set this variable or change its content.

## v5.8.8

Work around potential strict mode issues, #190.

## v5.8.7

Add parameter `ShowParameter` to `Build-Parallel`, #189.

## v5.8.6

Fix `Resolve-MSBuild.ps1` BuildTools 2022, #188.

## v5.8.5

Support MSBuild 17.0 (VS 2022).

## v5.8.4

Make the variable `$Job` read only, #185.

## v5.8.3

Use `$Job` variable instead of argument, #185.

## v5.8.2

`Enter-BuildJob` and `Exit-BuildJob` are called with the job script block as the first argument, #185.

## v5.8.1

Added the variable `$OriginalLocation`, where the build starts, #183.

## v5.8.0

Published [nuget.org/packages/ib](https://www.nuget.org/packages/ib/), the dotnet tool `ib`.

Removed `ib.cmd`, `ib.sh` from the package avoiding conflicts with the tool `ib`.\
The scripts are still available in the repository, slightly adjusted for their new roles.

Users decide which of the `ib` shell commands is more suitable for their scenarios.\
For details see [ib commands](https://github.com/nightroman/Invoke-Build/tree/main/ib#readme).

## v5.7.3

Add `$pwd` information to `exec -echo`, #179.

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

Add the robust helper `remove`, the alternative to `Remove-Item`, see #123

Tools

- *New-VSCodeTask.ps1* 1.1.6 - Confirm removal of not generated file.

## v5.2.1

- New switch `Latest` of `Resolve-MSBuild`, #122

## v5.2.0

- **New:** Alternative syntax of task parameters, kind of inline splatting, #119
- Add "missing output" message to incremental task processing, #120

Tools

- *Invoke-TaskFromVSCode.ps1* should save the file on invoking, #118
- Improve *Invoke-TaskFromVSCode.ps1* error info in some cases
- Support `viz.js` in *Show-BuildGraph.ps1*

## v5.1.1

- `Show-TaskHelp` - switches are shown after other parameters.
- Optimized calls of `Show-TaskHelp` from `Invoke-Build`.

## v5.1.0

New internal tool, #117

- The new tool *Show-TaskHelp.ps1* is included to packages.
- `Invoke-Build ... -WhatIf` uses the new `Show-TaskHelp`.

New external tool, #116

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

- Support colored output in AppVeyor, #103
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
cases, (#29).

Avoided cryptic errors on invoking scripts with invalid syntax and on resuming
builds with an invalid checkpoint file.

## v2 releases

Older release notes: [V2 Release Notes](https://github.com/nightroman/Invoke-Build/blob/main/Docs/V2-Release-Notes.md)
