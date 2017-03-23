
# Invoke-Build Release Notes

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

Event blocks instead of functions, see [#36](https://github.com/nightroman/Invoke-Build/issues/36).

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
