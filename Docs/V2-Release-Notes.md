# V2 Release Notes

## v2.14.7

Fixed #27, `Invoke-Builds` regression.

## v2.14.6

Faster preprocessing of special tasks `*`.

A new tool *New-VSCodeTask.ps1* is created. It generates VSCode tasks bound to
a specified or default build script tasks and Invoke-Build as a task runner.

*Convert-psake.ps1*

- Preserves original comments and empty lines.
- Adds comments about not supported `$psake` properties.
- Adds comments about incompatible cases of `exec`, `assert`.

## v2.14.5

- Revised collections and checks for missing and cyclic tasks.
- `Invoke-Builds` uses engine functions to avoid dupes and #21.

## v2.14.4

Resolved #22, checkpoints are stored before tasks.

## v2.14.3

Improved detection of color support, #21.

## v2.14.2

Fixed #20, persistent builds with cmdlet binding parameters.

## v2.14.1

Tweaks in error processing and satellite tools.

## v2.14.0

Added new command `equals` (alias of `Assert-BuildEquals`), mostly for tests.
Consider to use `equals X Y` instead of `assert (X -eq Y)`. It is simpler, it
avoids subtle PowerShell conversions, and its error message is more useful.

## v2.13.0

`Use-BuildAlias`: `*` is for auto detection of the latest build tools. Example:

    use * MSBuild

## v2.12.4

Fixed #17: *After* tasks should be added after *Before* tasks.

This fix changes the order of added tasks in the following case:

    task Task1                 # task with no own actions
    task After -After Task1    # at first After is added
    task Before -Before Task1  # then Before is added

After preprocessing the result task had unexpected reference order:

    task Task1 After, Before

After the fix the order of referenced tasks is changed to expected:

    task Task1 Before, After

## v2.12.3

- Fixed #16, the package is marked as `developmentDependency`.
- Fixed typo in help.

## v2.12.2

Added `InformationAction` and `InformationVariable` for v5.

## v2.12.1

Dot-sourcing lets specify the build root.

## v2.12.0

Only the core scripts are left in the package in order to keep it focused on
main tasks. Other tools are available at the project repository. A separate
package with tools may be created in the future if somebody needs this.

Excluded *Invoke-TaskFromISE.ps1*, *Show-BuildGraph.ps1*, *Show-BuildTree.ps1*
now allow *Invoke-Build.ps1* to be in the path but at first they still look for
it in their directories.

Added *Tasks/Param*. It shows how to create several tasks which perform similar
actions with some differences depending on parameters.

Added *Tests/Acknowledged.build.ps1*, acknowledged issues and various facts.

## v2.11.1

Fixed #12 `Write-Warning` fails in a `trap`.

## v2.11.0

This version improves Invoke-Build as a testing engine and slightly improves
information shown for normal builds. **Potentially incompatible changes**: if
scripts analyse result `Errors` and `Warnings` then they should be revised.

#### Aborted builds (Issue #9)

When an error happens before a build starts (missing task, cyclic reference,
script throws, and etc.) then the build footer shows this as `Build ABORTED`
(i.e. not even started) instead of `Build FAILED` (i.e. started and failed).

#### Improved result errors (Issue #10)

The result `Errors` list contains objects:

- `Error` - original error record
- `File` - current `$BuildFile`
- `Task` - current `$Task` or null for non-task errors

This new information is especially useful in testing:

    Invoke-Build ** -Safe -Result Result
    $Result.Errors [ | Format-List ]

Use `$Result.Errors` in order to just list all failures (as above) or produce
detailed reports. Error objects now contain enough details.

#### Improved result warnings (Issue #11)

The result `Warnings` list contains objects:

- `Message` - warning message
- `File` - current `$BuildFile`
- `Task` - current `$Task` or null for non-task warnings

Build footers as usual show warnings, with task and file now included.

## v2.10.4

Resolved #8. Improved footer messages and result list `Errors`:

- Avoided duplicated errors.
- Non-task errors are included.

## v2.10.3

Resolved #5. When `Safe` is used together with the special task `**` (invoke
`*.test.ps1`) then task failures stop current test scripts, not the whole
testing. This change is potentially incompatible, it may alter results of
`Invoke-Build ** -Safe`.

## v2.10.2

Resolved #6. `Out-String` should not be used by the engine.

## v2.10.1

Fixed incomplete error information when `-Safe` is used.

## v2.10.0

Invoke-Build features can be imported to normal scripts by dot-sourcing.
See `help Invoke-Build` or wiki *Dot Sourcing Build Features*.

## v2.9.14

Minor tweaks in the code and revised help.

Removed sample *Tasks* from the package.

## v2.9.13

- Documented the issue #4 in help. Namely, dynamic switches must be specified
  after positional parameters `Task` and `File`.
- Corrected parameter positions in *Show-BuildGraph.ps1*, even though it worked
  fine, interestingly.

## v2.9.12

- Resolved #3 (colored output from remote hosts).

## v2.9.11

- *ib.cmd*: corrected #2.
- Help shows default parameter values in a standard way.

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

- Test-tasks are allowed to fail without breaking the build. Errors are counted
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

- [`check`](https://github.com/nightroman/Invoke-Build/blob/main/Tasks/Check) -
Build scripts with `check` tasks represent sort of check-lists. As soon as a
`check` passes it is never invoked again, even in next builds. Scripts are
invoked repeatedly until all checks are passed (desired state achieved).

- [`repeat`](https://github.com/nightroman/Invoke-Build/blob/main/Tasks/Repeat) -
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
*TabExpansion2.ps1* or slightly adapted for other replacements of build-in
`TabExpansion2`. It completes arguments of parameters *Task* (task names from a
build file) and *File* (normally suggests available *.build.ps1* and
*.test.ps1* files).

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
wiki *Portable Build Scripts*.

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
