
# Invoke-Build Release Notes

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
