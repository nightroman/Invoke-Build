Invoke-Build Release Notes
==========================

## v2.4.5

*Build.ps1*: fixed issues on scripts with cmdlet binding parameters.

## v2.4.4

Replaced dark yellow build messages with cyan. Dark yellow looks like white or
gray in Microsoft PowerShell "noble blue" consoles. Besides, MSBuild prints
similar build messages as cyan.

## v2.4.3

Amended *TabExpansionProfile.Invoke-Build.ps1*. If it is used in ISE then
completion lists should show proper icons. If the referenced
`TabExpansions2.ps1` is used then update it, too.

## v2.4.2

Fixed

- PS v2/v3 differences of `Invoke-Build ** missing-directory`.
- *Build.ps1* with the special task `**`.

Amended *TabExpansionProfile.Invoke-Build.ps1*.

## v2.4.1

Finishing touches on dynamic parameters of *Build.ps1*.

Updated the wiki with information about recently added features.

* [Build.ps1](https://github.com/nightroman/Invoke-Build/wiki/Build.ps1)
* [TabExpansion2](https://github.com/nightroman/Invoke-Build/wiki/TabExpansion2)

## v2.4.0

**Dynamic build script parameters in Build.ps1**

If a build script parameters do not intersect with *Build.ps1* parameters then
they can be specified directly for *Build.ps1*.

Example. If a build script parameters are

    param
    (
        $Platform = 'Win32',
        $Configuration = 'Release'
    )

then it is fine to call it naturally

    Build -Platform x64 -Configuration Debug

instead of not so easy to type

    Build -Parameters @{Platform = 'x64'; Configuration = 'Debug'}

Note that TabExpansion works with dynamic parameters.

**TabExpansionProfile.Invoke-Build.ps1**

This new script is `TabExpansion2` profile with custom completers for
*Invoke-Build.ps1* and *Build.ps1*. It can be used either directly with
[TabExpansion2.ps1](https://farnet.googlecode.com/svn/trunk/PowerShellFar/TabExpansion2.ps1)
or slightly adapted for other replacements of build-in `TabExpansion2`.
It completes arguments of parameters *Task* (task names from a build file) and
*File* (normally suggests available *.build.ps1* and *.test.ps1* files).

**Warning on script output**

Output from scripts on adding tasks is treated as unexpected. It is intercepted
and written as a warning. Firstly, this catches a common mistake. Example: the
script outputs a script block instead of adding a task with it

    task Task1
    {
        ...
    }

Secondly, this avoids noise data on getting tasks for analysis.

**New special task ??**

The task `??` is used to get tasks without invoking. It replaces the old not so
easy to use approach. This new simple code

    $tasks = Invoke-Build ??

is used instead of

    $null = Invoke-Build ? -Result result
    $tasks = $Result.All

The task `?` is now used only to show brief task information.

This change does not affect normal build script scenarios. But wrapper scripts
which get tasks for analysis like *Build.ps1*, *Show-BuildGraph.ps1* should be
upgraded.

**Combined special tasks**

`?` and `??` can be combined with `**`.

Show all tasks from all *.test.ps1* files:

    Invoke-Build ?, **

Get task dictionaries for all *.test.ps1* files:

    Invoke-Build ??, **

Note that the helper *Build.ps1* supports these new features. In particular it
can be used now for getting task dictionaries (it was able only to display,
analyse, and etc. but not to return).

**Other changes**

The `Get-BuildFileHook` is dropped. Wrapper scripts should provide a file if
the default is missing. They can use a copy of the function `Get-BuildFile`.
This approach seems to be simple and natural comparing with a callback. For
example, see how *Build.ps1* uses `Get-BuildFile` and extends it.

## v2.3.0

`Build.ps1`

New switch `NoExit` tells to prompt "Press enter to exit".

## v2.2.0

`use` (`Use-BuildAlias`) accepts MSBuild version strings (e.g. `'4.0'`,
`'2.0'`) and resolves them to paths using information from the registry.

## v2.1.1

Adapted Invoke-Build for `Set-StrictMode -Version Latest`

## v2.1.0

New special task `**` invokes `*` (all tasks, normally tests) for all files
`*.test.ps1` found recursively in the current directory or a directory
specified by the parameter `File`. It simplifies invocation of tests
represented by tasks in several scripts in a directory tree.

Renamed some test scripts to `*.test.ps1` and made them called automatically
with the new special task `**`.

## v2.0.1

Minor improvements in *Invoke-Builds.ps1*. The key `File` in parameters is now
optional. The omitted one is resolved to the usual default build script. Added
a test.

Changed color of messages *Build < tasks > < file >* to dark green.

## v2.0.0

This version introduces major but mostly cosmetic changes in advanced features.
Scripts using these features should be upgraded. If some scripts are not going
to be upgraded then an old copy of tools can be used for building them. See
[Portable Build Scripts][1].

Renamed `Write-BuildText` to `Write-Build`.

Renamed `Assert-BuildTrue` to `Assert-Build`. This change is not breaking if
this function is used by its recommended alias `assert`.

Renamed `Enter-BuildScript`, `Exit-BuildScript` to `Enter-Build`, `Exit-Build`.
Old names are misleading, events are invoked before and after a build, not a
build script.

`Use-BuildAlias (use)` does not support the empty `Path` as a shortcut for
`[System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()`.

Changed syntax of incremental tasks to less cryptic and more like MSBuild.
Replaced parameters `Incremental`, `Partial` with `Inputs`, `Outputs`, and
`[switch]Partial`.

It is allowed to add two or more tasks with the same name. The last added wins.
So it is possible to redefine existing tasks. Well, it is also possible to use
the same name by mistake. Flexibility or safety? MSBuild chooses flexibility,
Invoke-Build follows.

Task parameter `After` tells to add a task to the end of job lists. It used to
be inserted after the last script job - this is often the same but not always.

Removed `Invoke-Build.ps1`'s parameter `Hook`. If the default script is not
found the command `Get-BuildFileHook` is called if it exists. See `Build.ps1`.

Changed build results of `Invoke-Build.ps1` and `Invoke-Builds.ps1` in order to
avoid excessive and duplicated data. See help.

`Invoke-Build.ps1`'s parameter `Result` always returns an instance of build
information. Its new property `All` contains all defined task objects.

Replaced exposed internal variables `BuildInfo`, `BuildList`, and `BuildHook`
with a new variable `*`. Build scripts should not use it. This change is not
breaking unless internal variables are used (illegal) or `${*}` is used in
scripts (unlikely).

Renamed the help file `Invoke-Build.ps1-Help.xml` to `Invoke-Build-Help.xml`.

## v1.5.2

**Potentially breaking but *minor* change**. Dropped support of nested lists in
job lists. Value of this feature is low because such cases are very rare and
unrolling is simple right in task definitions, see *Dynamic.build.ps1*.

Simplified checkpoint files. Do not use old checkpoints with the new engine.

Fixed false positive recoveries on protected task failures. Added tests.

Other mostly cosmetic changes in scripts, messages, and tests.

## v1.5.1

The engine sets the current location to the build root directory before calling
event functions. Amended *Checkpoint.build.ps1* and *Events.build.ps1* in order
to cover this.

## v1.5.0

Persistent builds are enabled by the new parameter `Checkpoint`. They can be
resumed at a failed task after fixing problems which are not critical for
repeating a failed task and processing remaining others.

New event functions `Export-Build` and `Import-Build` are used for persistent
builds with tasks that share some data, normally script scope variables.

New test `Checkpoint.build.ps1` shows main features of persistent builds. The
details are explained in its code comments.

Added the wiki page about persistent builds.

## v1.4.1

The internal `Write-Warning` (warning counter) is converted the true wrapper.
That is, it calls the native cmdlet instead of `Write-BuildText`. As a result:

- This fixes problems in functions writing data and warnings together.
- The build engine still counts warnings and displays them in the end.
- But warnings may not be "logged in the same way" as before.

## v1.4.0

The build engine defines and calls the following empty functions:

    * Enter-BuildScript - before the first task
    * Exit-BuildScript  - after the last task
    * Enter-BuildTask   - before each task
    * Exit-BuildTask    - after each task
    * Enter-BuildJob    - before each script job
    * Exit-BuildJob     - after each script job

Any of them can be redefined in scripts. See `help Invoke-Build.ps1`, section
*EVENT FUNCTIONS* for details. These events can be used for advanced logging,
initialization and releasing resources, etc.

## v1.3.2

*Invoke-Build.ps1*. Fixed use of not initialized `$BuildHook` in strict mode.

*Show-BuildGraph.ps1*. With the `Number` switch task script blocks are also
counted and their numbers are shown in task boxes. Note that this script is
still under construction, some changes based on the feedback are expected.

## v1.3.1

*Show-BuildGraph.ps1*

- Replaced parameter `Graph` with `Code`. Any proper DOT code is allowed.
- Switch `Number` tells to show task call numbers on graph edges.
- Tasks with code are shown as boxes, without code as ovals.
- Protected task calls are shown as dotted edges.

## v1.3.0

New script *Show-BuildGraph.ps1* builds and shows build task graphs using
[Graphviz](http://graphviz.org/). For an example see
[Wiki](https://github.com/nightroman/Invoke-Build/wiki/Visualization-of-Build-Graphs).

## v1.2.8

Partial incremental tasks. Automatic variable `$$` is not supported, use `$2`.

Adapted tests to PowerShell V3 Beta (changed error messages).

## v1.2.7

Adapted to PowerShell V3 CTP2.

Got rid of easy to type but controversial variable `$$`. There are issues in
PowerShell V3, bugs or not, Invoke-Build does not use this variable anymore.

As a result, it is recommended to replace automatic variables `$$` with `$2` in
all partial incremental task code (if any). This version supports both `$2`
(new) and `$$` (deprecated). `$$` will not be supported in vNext.

## v1.2.6

Refactoring of tests for decoupling and better grouping. Error cases moved from
*ErrorCases.build.ps1* and *.build.ps1* to other scripts (test sets, in fact).

## v1.2.5

Removed the questionable trick with empty `Write-Host` defined internally for
scripts invoked as parallel builds. This is up to scripts to decide how to
avoid host commands: remove, redefine, replace with `Write-Verbose`, ...

Parallel builds: code clean-up, minor fixes, new tests.

## v1.2.4

Parallel builds. Amended summary messages. Log files are UTF8. Added some non
ASCII output to parallel build tests.

Tests. Custom Format-Error is used instead of Out-String which does not work in
strict mode with some hosts due to internal errors.

## v1.2.3

New parameter switch `Safe`. It tells to catch/store build errors and return
quietly. It is needed for parallel builds (instead of a hack used before) but
it can be useful for regular builds, too.

Parallel builds use log files always, either specified by `Log` or temporary.
As a result, output is not discarded on timeout and less memory is used, too.

## v1.2.2

Parallel builds. New parameter `Timeout` and ability to log build outputs to
files. New test *Timeout* in *Parallel.build.ps1* shows how it works.

Removed some noise from logged errors and added the prefix "ERROR:" to make it
easier to search for error records in logs. Included position messages to final
build messages shown before the summary line.

Internal task object: renamed property `Info` to `InvocationInfo`. This may
break code performing task analysis.

## v1.2.1

Output of parallel builds produced before failures used to disappear, only
failure information was shown. Fixed, build output should be always shown.

## v1.2.0 - Parallel Builds

New script *Invoke-Builds.ps1* invokes parallel builds by *Invoke-Build.ps1*.
*Invoke-Builds.ps1* expects *Invoke-Build.ps1* to be in the same directory.
Such script tandems should work without conflicts with others, say, newer
versions in the path. See also: [Portable Build Scripts][1]

The engine script *Invoke-Build.ps1* does not require this new script. But the
engine is aware of it (creates an alias `Invoke-Builds`) and helps it to get
results from other runspaces easier:

* The parameter `Result` provides more ways to get results.
* The result property `Error` contains an error that stopped the build.

New demo/test script *Parallel.build.ps1* shows how parallel builds are used.

Fixed a subtle issue: special aliases should be set always, not just on the
first call. Use case: a build is invoked by a new engine but it explicitly
calls an old engine, for example, frozen together with some sources.

## v1.1.2

**Errors**

Improved source information of some errors thrown by the engine, for example,
incremental inputs/outputs errors. Instead of pointing to not useful internal
`throw` they show where Invoke-Build.ps1 or the wrapper Build.ps1 is invoked,
this is more useful for troubleshooting. Errors with amended information are
created in addition, initial errors can be found in the `$Error` list.

Removed target objects from some errors as presumably redundant. They are shown
in error messages anyway. Other use of them is unlikely practical.

**Exposed variables**

The special variable `$_` is now visible. Scripts and tasks can use it as their
own, that is assign at first and then use. They must not make any assumptions
about its incoming value and use it without assignment.
See also: [Special Variables][3].

## v1.1.1

Slightly changed output. Minor engine and test changes.

## v1.1.0

This release is the outcome of 1.0 series (stabilization of the tool set and
concepts). From now on new features will be normally associated with minor
version numbers. This release itself contains just improvements.

Found and fixed a case when the internal alias *Invoke-Build* was not set.
See also: [Portable Build Scripts][1].

Work around "Default Host" exceptions on setting colors in scenarios like

    [PowerShell]::Create().AddScript("Invoke-Build ...").Invoke()

New test *TestSelfAlias* covers both issues. New test *TestStartJob* invokes
build as a background job.

## v1.0.41

Initial task checks process all tasks regardless of `If` conditions. This finds
issues earlier and also makes checks useful in more scenarios.

The helper task `?` (show/get tasks) now checks tasks in order to find issues
earlier. Wrappers using `?` may assume that tasks are valid. As a result, the
wrapper *Build.ps1* is simplified.

The helper task `*` (invoke all) was able to miss tasks with cyclic references.
This is fixed and covered by tests.

## v1.0.40

Cosmetic changes in the engine and help.

Removed some redundancies from tests.

## v1.0.39

New special task `*` (in addition to `?`). `*` tells to invoke all independent
tasks, i.e. all tasks starting with roots. This is very useful for scripts with
test tasks, one does not have to have a master task that calls all the others.
Besides, `*` ensures that there is no test not called by mistake.

Thus, some obsolete/redundant tasks were removed from scripts in *Demo*.

New *Invoke-Build* parameter *Hook* for extensions. The only hook for now is
*GetFile* which is used by *Build.ps1*. *Get-BuildFile* is exposed for this.

## v1.0.38

More info in invalid task errors and more such tests.

## v1.0.37

Script processing checks for "no tasks" first and fails if this is the case.
If it is not a build script then other checks and messages can be confusing.

`Add-BuildTask` (`task`) uses named parameter sets Incremental and Partial.
This should not affect build scripts but, just in case, some errors changed.

Tweaks in scripts and tests.

## v1.0.36

Adapted *Invoke-Build.ps1*, *Build.ps1*, and tests for notorious paths with
square brackets. Caution: this is done to some reasonable extent, some paths
choke PowerShell anyway, like this weird but valid directory name:

    ] [ `] `[

## v1.0.35

Moved log messages "Task skipped" from preprocessing to processing phase. As a
result, a task with false condition is logged every time when a task is called.

Internal engine functions now use weird names, just in case, to avoid clashes.

## v1.0.34

*Build.ps1*: fixed not standard PowerShell line separators in messages with
InvocationInfo. Added two more tests to *Demo/Wrapper.build.ps1*.

Minor tweaks.

## v1.0.33

`task`: the job list is unrolled internally. Thus, it is fine to mix single
jobs and job collections in the same list. See new *Demo/Dynamic.build.ps1*
which shows dynamic task creation and also covers unrolling.

Removed do-not-dot-source check from `Use-BuildAlias` (`use`). Otherwise for
consistency such paranoia checks should be in all functions, this is too much.

Amended checks of varying output in *Demo/Wrapper.build.ps1*, task *Summary*.

*Demo* tests: replaced some culture specific checks of core error messages with
neutral checks. Tests are supposed to work on any machine and with any culture.

## v1.0.32

Amended error message on a script block returned by a build script.

*Build.ps1*

* Fixed search for the build script in the parent tree (it used to stop on a directory with no candidates).
* Added yet missing *Demo/Wrapper.build.ps1* which tests all *Build.ps1* features.
* Documentation comments.

## v1.0.31

`property`: variables with null values are treated as not existing. In other
words, `property` never gets nulls. There is a little chance that this breaks.

`Write-BuildText` uses try/finally to restore colors on *Ctrl-C* as well.

Tweaks of the engine, output, and documentation.

## v1.0.30

If the parameter `Task` is '.' and the the task '.' is not defined then the
first added task is invoked. In other words, the argument '.' has the same
effect as if the parameter is not specified.

*Build.ps1*

* Ignored the pseudo task `?` when it is used with the switch `-Tree`.
* Switch `-Comment`: Fixed extra empty lines. It works on its own, too.

## v1.0.29

*Build.ps1*: New switch *Comment* (with *Tree*) tells to include comments:

    # show the task tree for Pack and include task comments
    Build Pack -Tree -Comment

## v1.0.28

Amended default file resolution and built-in help.

## v1.0.27

`Invoke-Build ? -Result ...` - gets the task collection without invoking tasks.

New switch `Tree` of *Build.ps1* is used to show task parents and trees.

Tweaks in default file discovery and path resolution.

## v1.0.26

New script *Build.ps1* - Invoke-Build wrapper, mostly for command prompt.

Build scripts are allowed to alter `$BuildRoot`. Use cases: 1) when it is not
suitable to keep a file where it works; 2) the same file is used for several or
variable directories.

`$WhatIf` is set to `$true` when `?` is specified as a task (view tasks).

Alias `Invoke-Build` is set internally to the full path of the invoked script.
Reasons: faster nested calls, ability to use *Invoke-Build.ps1* copies, not in
the path, too.

`assert`: allow any object as the condition, to require `[bool]` is too much.

Amended the first line of the build output.

## v1.0.25

Amended error messages in `Use-BuildAlias` and other tweaks. New tests.

## v1.0.24

Scripts can change `$ErrorActionPreference` at the script level once for all
their tasks. Reminder: the default value is *Stop*.

The special command [`. Invoke-Build`] also shows the current version. Tip: for
scripts there is `Get-BuildVersion`.

Amended error messages and source information in several error cases.

## v1.0.22, v1.0.23

**Breaking changes**

Invoke-Build main parameters are `Task`, `File`, `Parameters`, as they used to
be. The removed combined parameter `Script` was not intuitive, according to the
feedback.

Replaced task parameters `Inputs` and `Outputs` with `Incremental` and
`Partial`. New parameters are hashtables with a single entry: key is the
inputs, value is the outputs. As a result, the outputs can be defined as a
script block for any kind of incremental task, partial or not. (NB: script
blocks are lazy and preferable in some cases for better performance).

## v1.0.21

*v1.0.20* continued. Build scripts are not allowed to output script blocks. It
makes no sense and, more likely, indicates a script job defined after a task,
not as a parameter. As a result, this script fails:

    task task2 task1
    {
        ...
    }

As a result, null or missing job lists in tasks are allowed again.

## v1.0.20

Tasks still may have empty job lists (e.g. jobs can be created dynamically and
nothing is actually created). But null or missing job lists are not allowed.
As a result, this known mistake is now an error:

    task Name
    {
        ...
    }

Fixed a bug in `Invoke-Build ?`.

## v1.0.18 - v1.0.19

Documentation moved to the external file *Invoke-Build.ps1-Help.xml*. It should
be copied to the same directory where *Invoke-Build.ps1* is located.

New parameter `Result`, the optional name of variable to be created with build
statistics: invoked task list, messages, error count, and warning count. It can
be used for analysis of failed tasks and their errors, task durations, and etc.

Slightly changed build result messages.

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
This is somewhat similar to what MSBuild does.

## v1.0.9

Tasks support `After` and `Before` parameters, analogues of `AfterTargets` and
`BeforeTargets` of *MSBuild* targets.

If build tasks are not specified and the "." task does not exist then the first
added task is invoked.

At this point *Invoke-Build* concepts become quite similar to *MSBuild*, see
[Comparison with MSBuild][2].

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

[1]: https://github.com/nightroman/Invoke-Build/wiki/Portable-Build-Scripts
[2]: https://github.com/nightroman/Invoke-Build/wiki/Comparison-with-MSBuild
[3]: https://github.com/nightroman/Invoke-Build/wiki/Special-Variables
