
Invoke-Build Release Notes
==========================

## v2.9.10

*Invoke-TaskFromISE.ps1*, *Show-BuildGraph.ps1*, *Show-BuildTree.ps1*

- They expect *Invoke-Build.ps1* to be in the same directory. Pros: 1) to be in
  the path is optional; 2) this approach avoids potential version conflicts.

*Show-BuildTree.ps1*

- It does not show upstream tasks by default, they may look confusing.
- New switch `Upstream` tells to show upstream tasks for each task.

Minor inner changes.

## v2.9.9

- *ib.cmd* shows help on `/?`
- Custom task `file` - fixed propagation of the source
- DynamicParam - replaced `Get-Variable` with `$PSBoundParameters`

## v2.9.8

Users ask for a common cmd.exe helper. I was reluctant for some reasons but now
is a good time, perhaps. Here is the proposal based on my own practice.

- *ib.cmd* is the proposed Invoke-Build helper for cmd.exe.
- For similar experience in interactive PowerShell use an alias `ib`.

Note that scripts should continue to use the command `Invoke-Build`. The `ib`
commands should be used with cmd.exe (*ib.cmd*) and in interactive PowerShell
(alias of *Invoke-Build.ps1* defined in the profile).

Custom tasks

- Added the sample custom rake-like task `file`. It is not a big deal but it
  still may be useful. Besides, it comes with examples of incremental tasks.

## v2.9.7

Task help (*experimentally*). The *Jobs* is an array, not a text. With
many jobs this avoids dropped *Synopsis* on default formatting.

New script *Convert-psake.ps1* converts psake build scripts to Invoke-Build.

## v2.9.6

Fixed text of error messages on explicitly set task errors.

## v2.9.5

Revised errors

- Removed irrelevant data from error messages in build summary.
- Amended error messages about issues in task Inputs and Outputs.
- Build result property `Errors` contains error objects, not messages.

Custom tasks

- Redesigned the custom task `retry` so that the function `Invoke-RetryAction`
  may be used on its own, see an example in *Retry.build.ps1*.

## v2.9.4

Custom tasks `retry` and `test`

- `Inputs` and `Outputs` are supported, `Partial` is not.
- Slightly relaxed requirements for `Jobs`.
- `test`: an upstream error is propagated.

Property `Jobs`

- The property `Jobs` of internal task objects is documented and can be used
  for reading by custom tasks and by external tools for task analysis.

## v2.9.3

Corrected internal processing order. Because `Done` still may fail a task it
should be invoked before storing a checkpoint for a persistent build.

New sample custom task `retry`, see *Tasks\Retry*. Special parameters are
`RetryTimeout` and `RetryInterval`, similar to `Set-BitsTransfer`.

## v2.9.2

**Revised build output**

- Added task names to some error messages for consistency.
- Omitted not so useful job details in action headers and task footers.
- Error summary is not written by default. It was only useful in very complex
builds and needed because the switch `Summary` was not originally introduced.

**Explicitly set task errors**

- If a task does not fail but sets its `$Task.Error` then it is still treated as
failed. The build does not stop in this case. This can be used effectively is
special cases, e.g. in tasks like `test`.

**Sample custom task `test`**

- [`test`](https://github.com/nightroman/Invoke-Build/blob/master/Tasks/Test) -
  Test-tasks are allowed to fail without breaking the build. Errors are counted
  and written as usual. `test`'s jobs are optional simple references followed
  by a single action. If a reference fails an action is skipped.

**Package**

- The directory *Tasks* is included to the package. Ideally, use these tools
as samples for your own, they are not parts of the engine, strictly speaking.

## v2.9.1

Fixed incorrect build time written with `Summary`.

## v2.9.0 Custom tasks

This release introduces new task programming techniques and sample tools.

Added new `task` parameters `Data`, `Done`, and `Source`. They are designed for
custom tasks, wrappers which add extra features and introduce new DSL commands.
`Data` and `Done` may be useful in normal tasks. `Source` is for wrappers only.

Sample custom tasks:

- [`check`](https://github.com/nightroman/Invoke-Build/blob/master/Tasks/Check) -
Build scripts with `check` tasks represent sort of check-lists. As soon as a
`check` passes it is never invoked again, even in next builds. Scripts are
invoked repeatedly until all checks are passed (desired state achieved).

- [`repeat`](https://github.com/nightroman/Invoke-Build/blob/master/Tasks/Repeat) -
Build scripts with `repeat` tasks represent sort of schedules. They are invoked
periodically. Each `repeat` task is invoked or skipped according to its defined
time span and stored last done time.

DSL commands `check` and `repeat` are defined in scripts `*.tasks.ps1`. They
are dot-sourced in build scripts before the first use of new custom tasks.
Commands `check` and `repeat` are used almost in the same way as `task`.

These tools are ready to use in scripts but not included to the package. They
are extensions, not parts of the engine. The engine only makes them possible.
Q: Should they be included to the package anyway?

TODO: Think of a custom task `test` which is allowed to fail without breaking
the build. Some minor support from the engine may be needed for proper error
counting and reporting.

P.S. Imagine, one may want to request a new feature, say, `-Retry...` for tasks.
Perhaps this will not be accepted after investigation. Well, it is now up to an
author to define such a task with another DSL name and any required parameters:

    # Import task library for "retry".
    . Retry.tasks.ps1

    # Synopsis: Note that help comments are possible for custom tasks.
    retry TaskName -RetryCount 5 -RetrySec 60 -ConfirmRetry {
        ...
    }

## v2.8.1

**Task help comments**

- Improved getting of task synopsis from comments.
- Fixed unexpected help property order in PS v2.0.

## v2.8.0

**Documentation comments**

Help task *?* returns objects describing tasks. Properties:

- *Name* - task name
- *Jobs* - comma separated task names and own actions shown as `{}`
- *Synopsis* - task synopsis from the preceding comment `# Synopsis: ...`

Returned objects are formatted as three column table by default. If default
formatting is not good enough use custom formatting, e.g.:

    Invoke-Build ? | Format-Table -AutoSize
    Invoke-Build ? | Format-List Name, Synopsis

***Show-BuildTree.ps1***

- Always shows task synopsis, if any.
- Removed not needed switch *Comment*.

**$Task, step 2. Potentially incompatible**

- `$Task` is now constant, `Enter|Exit-BuildTask` and `Enter|Exit-BuildJob`
  cannot override it, say, accidentally.
- Event functions `Enter|Exit-BuildTask` do not accept a task as an argument,
  use the automatic variable `$Task` instead.
- Event functions `Enter|Exit-BuildJob` do not accept a task as the first
  argument, use `$Task` instead. The job number became the first argument.

With this step integration of the automatic variable `$Task` is complete.

## v2.7.4 $Task

**Default script resolution**

The script specified by `$env:InvokeBuildGetFile` (gets a non standard default
build file) is invoked with the full directory path as an argument. It may be
invoked several times during the directory branch search with each path passed
in. Old scripts should work fine but some of them may be simplified now.

**Automatic variable $Task. Step 1**

A new automatic variable `$Task` represents the current task instance. It is
available for the task script blocks defined by parameters `If`, `Inputs`,
`Outputs`, `Jobs` and the event functions `Enter|Exit-BuildTask` and
`Enter|Exit-BuildJob`.

Why? Some advanced task scripts need this instance (e.g. shared between tasks).
A common variable `$Task` seems to be simpler than use of a parameter in each
of 8 above code pieces. Let's keep parameters available for something else.

**Potentially incompatible**

Build scripts with the parameter `$Task` or script variable `$Task` may fail.
Rename this variable. The parameter `$Task` is not good anyway because it
conflicts with Invoke-Build and cannot be used as the dynamic parameter.

As far as `Enter|Exit-*` are invoked in the scope where `$Task` is defined,
make sure they do not change it. Other task code may change it in its own
scope. But such hiding of the system variable is not recommended.

**Step 2. The next version**

`Enter|Exit-BuildTask` and `Enter|Exit-BuildJob` will not be accepting the task
as the first argument. The new variable `$Task` should be used instead. Most of
scripts may be prepared now. Change of `Enter|Exit-BuildJob` may be breaking,
the second parameter will become first.

## v2.7.2, v2.7.3

Added missing *Invoke-TaskFromISE.ps1*.

Minor tweaks in code and help.

## v2.7.1

This version mostly completes changes announced for v2.7.

*Invoke-Build*

- *Build.ps1* features moved to *Invoke-Build*:
    - Switch `Summary` tells to write summary after build.
    - Advanced resolution of the default build script.
- Shows some more details in task listings.
- Logs task starts as "Task X:".

*Show-BuildTree.ps1*

- The rest of *Build.ps1* transformed to *Show-BuildTree.ps1*.
- By default it shows the default task tree, not all trees.
- The special task `*` tells to show all root task trees.

*TabExpansionProfile.Invoke-Build.ps1*

- Removed not needed *Build.ps1* completers.

## v2.7.0 - Dynamic parameters

**Persistent builds, incompatible change**

Invoke-Build uses the new switch `Resume` in order to resume persistent builds.
It makes use of persistent builds easier and avoids conflicts with dynamic
parameters and coming soon changes.

The new switch must be added to old commands which resume builds. Hopefully it
should not break much because resuming is often supposed to be done manually.

**Dynamic parameters**

As far as *Build.ps1* dynamic parameters work well, *Invoke-Build.ps1* adopts
them, too. Dynamic parameters make command lines simple and neat. Compare:

New way, it really cannot be simpler:

    Invoke-Build -Configuration Release -Platform x64

Old way, still used in special cases:

    Invoke-Build -Parameters @{Configuration = 'Release'; Platform = 'x64'}

Mind an extra bonus: TabExpansion works fine with dynamic parameters.

**Coming soon in v2.7**

*Build.ps1* features to be moved to *Invoke-Build*:

- Advanced resolution of the default build script.
- Switch `Summary` to write summary after build.
- Switch `NoExit` will be dropped.

## v2.6.3 - PS v4.0 upgrade

*Build.ps1*: Adjusted for the new common parameter *PipelineVariable*.

## v2.6.2

*Invoke-TaskFromISE.ps1* also supports the form `task [...] -Name TaskName`.
Still, not all possible forms are recognized, see the script help notes.

Avoided a recently introduced internal variable exposed to tasks.

## v2.6.1

*Invoke-TaskFromISE.ps1*

This new script invokes the current task from the build script being edited in
PowerShell ISE. It is invoked either in ISE or in PowerShell console. See the
script help comments for the details, e.g. how to associate with shortcuts.

## v2.6.0

**Easier persistent builds**

Build script parameters are automatically exported and imported on persistent
builds. Custom `Export-Build` and `Import-Build` do not have to care of them.
Moreover, some script variables may be declared as parameters simply in order
to be persistent and `Export-Build` and `Import-Build` may be dropped if they
deal with these variables and do nothing else.

Reminder: checkpoint files from other versions must not be used.

## v2.5.2

Minor tweaks in help.

*Build.ps1* - There was a subtle conflict between the parameter `Checkpoint`
and advanced resolution of `File`. Instead of introducing caveats for `File`
and making things more complex we drop `Checkpoint`, i.e. it should be used
with *Invoke-Build.ps1*, not with the command line helper *Build.ps1*.

Notes:

- If somebody wants this feature back then submit a request with reasons.
- This change is "not breaking", *Build.ps1* is for typing in command lines.

## v2.5.1

Function and variable names starting with `*` are reserved for the engine. For
technical reasons they cannot be completely hidden from scripts. Scripts should
not use functions and variables with such names. It is unlikely that they ever
do this but this is possible and should be avoided.

## v2.5.0

Some changes in terminology and syntax, not breaking for now. Allowed to fail
task references are now called "safe". They are created by the new command
*job* (*New-BuildJob*) with the switch *Safe*. In other words,

DO (new):

    task Task2 (job Task1 -Safe), { ... }

DON'T (old):

    task Task2 @{ Task1 = 1 }, { ... }

The new syntax is less cryptic, self describing, and easy to extend.

The old syntax for now works as well. But it is deprecated, not documented, and
very likely will stop working if the command *job* introduces more options.

## v2.4.7

Issue #1. Per user request, reduced density of the source code of
*Invoke-Build.ps1*, for better readability, easier debugging, etc.

Joined two internal functions `*U1` and `*U2`.

## v2.4.6

Amended documentation.

The first line "Build ...": write resolved task names, i.e. write the actual
default task name instead of nothing or `'.'` and task list instead of `'*'`.

*Demo* scripts are excluded. They are more boring tests than useful examples.
In any case they are available online at the project site.

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
