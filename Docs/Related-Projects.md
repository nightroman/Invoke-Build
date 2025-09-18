# Related Projects

## [Pask](https://github.com/lsgroi/Pask)

Task-oriented PowerShell build automation for .NET based on a set of conventions.
It leverages Invoke-Build and it consists of a set of predefined tasks and the
ability to create custom ones.

## [ModuleBuild](https://github.com/zloeber/ModuleBuild)

A scaffolding framework which can be used to kickstart a generic PowerShell
module project with an Invoke-Build backend for regular deployments and other
automated tasks. This project helps make everything about starting,
documenting, building, and eventually releasing your module to the PSGallery a
breeze.

## [OneBuild](https://github.com/lholman/OneBuild)

`OneBuild` is a modular set of convention based .NET solution build scripts
written in PowerShell, relying on `Invoke-Build` for task automation.

## [PowerTasks](https://github.com/shaynevanasperen/PowerTasks)

A PowerShell task runner based on `Invoke-Build`. `PowerTasks` was created in
order to remove the boilerplate code from build scripts.

## [red-gate/build-script-template](https://github.com/red-gate/build-script-template)

This repo contain an example/template that could be used when adding a build script to a project.

- We have a PowerShell script that runs the build. This script does everything,
  including gathering dependencies, generating version numbers, compiling,
  running tests, building and publishing NuGet packages. A build on TeamCity
  should, ideally, be a call to this script, and it should produce the same
  output as running it locally.
- We use `Invoke-Build` as our 'make'.
- We have a `build\_init.ps1` script that defines the entry points for the PowerShell commands.
