Invoke-Build Release Notes
==========================

## v1.0.17

**Breaking changes**

Revised *Invoke-Build* parameters. New approach makes it easier to invoke build
scripts with many parameters. It also enables TabExpansion of script parameters
and ability to invoke tasks in scripts located somewhere in the path.

## v1.0.16

Build scripts and task scripts are now invoked with `$ErrorActionPreference`
set to `Stop`. Otherwise it is too easy to miss serious errors. Scripts and
tasks can set their own local `$ErrorActionPreference`.

Dropped support of *master* scripts and removed related function `Start-Build`.
Master scripts have pros and cons but after all they are basically not better
than classic scripts.

## v1.0.15

Introduced the function `Get-BuildProperty` and its alias `property`.

Amended the error message on a build script with no tasks.

## v1.0.14

Fixed a bug dealing with splatting and the first parameter default value.

## v1.0.13

Empty/dummy tasks with no jobs are allowed (just like MSBuild empty targets
with no dependencies and tasks). They are used in rare but possible scenarios.

## v1.0.12

Amended error messages in `Use-BuildAlias`.

More tests in *Use.build.ps1*.

## v1.0.11

Task names are logged exactly as they are defined by `task`, not as referenced
by the parameters or other tasks.

`Use-BuildAlias` uses `-ErrorAction Stop` and fails if a directory is missing.

## v1.0.10

`Before` tasks are added before the first script job. `After` tasks are added
after the last script job. If there is not a script job they are just added.
This logic allows to to reproduce MSBuild scenarios.

## v1.0.9

Tasks support `After` and `Before` parameters, analogues of `AfterTargets` and
`BeforeTargets` of *MSBuild* targets.

If build tasks are not specified and the "." task does not exist then the first
added task is invoked.

At this point *Invoke-Build* concepts become quite similar to *MSBuild*, see
[Comparison with MSBuild](https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-MSBuild).

## v1.0.8

Simplified `assert`. Minor engine and test tweaks.

## v1.0.7

Task errors in `If`, `Inputs`, and `Outputs` are not treated as build fatal if
a tasks is called protected. Really, they are not different from other task job
errors, any can be either a programming bug or a build issue. A task that calls
a culprit task can analyse its errors by `error` and decide to fail or not.

Introduced automatic helper variables for incremental task scripts. See the
`task` help, tests in *Incremental.build.ps1*, and the task `ConvertMarkdown`
in *Build.ps1*.

## v1.0.6

**Breaking changes**

`Use-BuildFramework` (alias `framework`) is transformed into `Use-BuildAlias`
(alias `use`). For .NET frameworks it works as it used to, only the command
names have to be updated. But now it can be used with any tool directory, not
necessarily .NET (for example a directory with scripts).

Incremental build: full input paths are piped, not file system items. It just
looks more practically useful to deal with full paths. Example: *Build.ps1*,
task `ConvertMarkdown`.

## v1.0.4, v1.0.5

Added support of incremental and partial incremental builds with new task
parameters `Inputs` and `Outputs`.

## v1.0.3

Errors in task `If` blocks should be fatal even if a task call is protected.

## v1.0.2

Task `If` conditions are either expressions evaluated on task creation or
script blocks evaluated on task invocation. In the latter case a script is
invoked as many times as the task is called until it gets `true` and the task
is invoked.
