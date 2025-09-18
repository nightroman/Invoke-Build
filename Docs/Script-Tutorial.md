# Script Tutorial

See also [01-step-by-step-tutorial](https://github.com/nightroman/Invoke-Build/tree/main/Tasks/01-step-by-step-tutorial) from simple to featured script.

## Hello World example

```powershell
task Hello {
    'Hello, World!'
}
```

If you name your script like `*.build.ps1`, e.g. `Hello.build.ps1`, then it can
be run by a simple command:

```powershell
# Run from the directory of Hello.build.ps1
Invoke-Build
```

If no task name is passed, Invoke-Build runs the default task `.` if it is
defined. Otherwise it runs the first task found, `Hello` in this example.

Build output looks like:

    Build Hello ...\Hello.build.ps1
    Task /Hello
    Hello, World!
    Done /Hello 00:00:00.01
    Build succeeded. 1 tasks, 0 errors, 0 warnings 00:00:00.02

## A more realistic example

This script defines three tasks:

- `Build` builds a C# project
- `Clean` removes temp files
- `.` invokes `Build` and `Clean`

```powershell
use 15.0x86 MSBuild

# Synopsis: Build the project.
task Build {
    exec { MSBuild Project.csproj /t:Build /p:Configuration=Release }
}

# Synopsis: Remove temp files.
task Clean {
    remove bin, obj
}

# Synopsis: Build and clean.
task . Build, Clean
```

`Invoke-Build` without parameters runs the default task `.` to build the project and then clean up.

Points of interest:

- `use` (alias of `Use-BuildAlias`) lets you directly call external tools, like MSBuild in this case
- `exec` (alias of `Invoke-BuildExec`) runs a command (usually .exe) and stops with error on unsuccessful exit code
- `remove` (alias of `Remove-BuildItem`) removes temporary files and directories much easier than using `Remove-Item`
- Tasks `Build` and `Clean` each consist of one script job (action), and do not reference other tasks
- The task `.` references two other tasks and does not have its own script job (no action)
- The task `.` is invoked by default
- Help comments `# Synopsis: ...`

You can pass multiple tasks to Invoke-Build, for example:

```powershell
# This explicitly runs both tasks, "Clean" and "Build"
Invoke-Build Clean, Build
```

Help comments are shown by the special pseudo task `?`:

    PS> Invoke-Build ?

    Name  Jobs         Synopsis
    ----  ----         --------
    Build {}           Build the project.
    Clean {}           Remove temp files.
    .     Build, Clean Build and clean.

## Jobs are references and actions

Task jobs are defined by the parameter `Jobs` with its name often omitted. Jobs
are references to other tasks and own script block actions. Jobs are invoked in
the specified order.

Unlike in many other task runners, task references do not have to precede own
actions. A task may reference tasks that it depends on and also tasks to be
invoked after own actions, i.e. continuation tasks.

Examples of tasks with various jobs:

```powershell
# Dummy task with no jobs
task Task1

# Alias of another task
task Task2 Task1

# Combination of tasks
task Task3 Task1, Task2

# Simple action task
task Task4 {
    # action
}

# Typical complex task: referenced task(s) and one own action
task Task5 Task1, Task2, {
    # action after referenced tasks
}

# Possible complex task: actions and tasks in any required order
task Task6 {
    # action before Task1
},
Task1, {
    # action after Task1 and before Task2
},
Task2, ...
```

## Script parameters for tasks

Build script parameters are standard PowerShell script parameters.
They are available to the script code for reading and writing as `$ParamName`,
and to all tasks for reading as `$ParamName` and for writing as `$script:ParamName`.

Note: script parameters are usual script variables (see later). The only
difference is that their values can be specified upon invoking a script.

In the previous example the task *Build* builds the *Release* configuration.
This slightly modified script makes this configurable:

```powershell
param(
    $Configuration = 'Release'
)

use 15.0x86 MSBuild

task Build {
    exec { MSBuild Project.csproj /t:Build /p:Configuration=$Configuration }
}
```

The command `Invoke-Build Build` still builds the *Release* configuration due
to the script parameter's default value, but it is now possible to specify and
build *Debug* as well:

```powershell
Invoke-Build Build -Configuration Debug
```

Yes, it's that simple. Script parameters are specified for `Invoke-Build`,
thanks to its dynamic parameters propagated from the build script.

Note that build scripts cannot use parameters reserved for the engine:
`Task`, `File`, `Result`, `Safe`, `Summary`, `WhatIf`.

## Script variables for tasks

Build script variables are standard PowerShell variables in the script scope.
Variables are available to the script code for reading and writing as `$VarName`,
and to all tasks for reading as `$VarName` and for writing as `$script:VarName`.

**Example:** The variable `$Tests` is defined in the script scope and available
to all tasks, including tasks defined before the variable. This is because tasks are
invoked after the whole script is evaluated:

```powershell
$Tests = 'SmokeTests.build.ps1', 'MoreTests.build.ps1'

task Test {
    foreach($_ in $Tests) {
        Invoke-Build * $_
    }
}
```

**Note:** The special task `*` used in this example invokes all tasks starting
from roots of task trees. It is normally used on testing with tests defined as
build tasks. Tests are often invoked all together, hence the special task `*`.

Nested scripts invoked by Invoke-Build have their own script scopes with their
own parameters and variables. Parent scripts' variables can be accessed normally, for
reading only. For example, the variable `$Tests` is available in the parent scope
for the nested scripts *SmokeTests.build.ps1* and *MoreTests.build.ps1*.

Tasks may use existing script variables, or may create new ones.
New script variables are typically created for use in other tasks.

**Example:** The task *Version* gets the file version and stores it in a
script variable with `$script:Version = ...`. Tasks *Zip* and *NuGet* require
this task before their own scripts. Thus, these tasks can reference the
script variable `$Version` and use it for package names:

```powershell
task Version {
    $script:Version = (Get-Item Project.dll).VersionInfo.FileVersion
}

task Zip Version, {
    exec { & 7za a Project.$Version.zip Project.dll }
}

task NuGet Version, {
    exec { NuGet pack Project.nuspec -Version $Version }
}

task PackAll Zip, NuGet
```

## Tasks are invoked once

This is the main rule of build flows. A task can be referenced by other tasks
many times. But as soon as it is invoked, its contribution to a build is over.

When the task *PackAll* is invoked in the previous example then *Version* is
referenced twice by the tasks scheduled for the build, at first by *Zip* and
then by *NuGet*. But in fact it is invoked only when *Zip* calls it.

To invoke something several times, use functions, see [#79](https://github.com/nightroman/Invoke-Build/issues/79).

## Build "properties"

Invoke-Build "properties" are usual PowerShell script variables and parameters,
like MSBuild properties defined in XML scripts (variables) and properties that
come from command lines (parameters), or environment variables.

MSBuild deals with environment variables using the same syntax. In contrast,
Invoke-Build scripts do not use environment variables in the same way. They
should be referenced as `$env:var` or obtained using `property`. The latter
gets the value of session or environment variable or the optional default.

**Example:** `$DevModuleDir` or `$Configuration` may come to the script below
in three ways: as script parameters, as variables defined in a parent scope,
and as environment variables. `(property DevModuleDir)` throws an error if the
property is not found. But `(property Configuration Release)` does not fail, it
uses the default value *Release*.

```powershell
param(
    $DevModuleDir = (property DevModuleDir),
    $Configuration = (property Configuration Release)
)

task Install {
    Copy-Item Bin/$Configuration/MyModule.dll $DevModuleDir/MyModule
}
```

**Caution**

Build properties should be used sparingly with carefully chosen distinctive names.
Avoid them in [Persistent Builds](Persistent-Builds.md) because properties rely on external data.

## Conditional tasks

The task parameter `If` specifies a condition, either a value evaluated on
creation or a script block evaluated on invocation. If it is present and
evaluated to false then the task is not invoked.

In the following example the task *MakeHelp* is invoked only if the current
configuration is *Release*:

```powershell
param(
    $Configuration = 'Release'
)

task MakeHelp -If ($Configuration -eq 'Release') {
    ...
}

task Build {
    ...
},
MakeHelp
```

Note that the task *MakeHelp* is still defined even if its condition is not
true. Thus, other tasks may refer to it, like the task *Build* does.

If the variable `$Configuration` is supposed to change during the build and the
task depends on its current value then a script block should be used instead:

```powershell
task MakeHelp -If {$Configuration -eq 'Release'} {
    ...
}
```

If a condition is a script block and a task is called more than once then it is
possible that it is skipped at first due to its condition evaluated to false
but still invoked later when its condition gets true.

## Safe task references and errors

If a task emits a terminating error then the build fails unless the task is
referenced as safe (`?name`) by the calling task and other tasks having a
chance to be invoked. This also applies to task names in command lines.

Use `Get-BuildError` in order to get errors of safe referenced tasks.

In this example *Task2* calls *Task1* safe and then checks for its error:

```powershell
task Task1 {
    # code with potential failures
    ...
}

task Task2 ?Task1, {
    if (Get-BuildError Task1) {
        # Task1 failed
        ...
    }
    else {
        # Task1 succeeded
        ...
    }
}
```

## Task jobs altered by other tasks

The task parameters `After` and `Before` are used in order to alter build task
jobs in special cases, for example if a build script is imported (dot-sourced)
and its direct changes are not suitable.

```powershell
task Build {
    # original Build code
}

task BeforeBuild -Before Build {
    # when Build is called this code is invoked before it
}

task AfterBuild -After Build {
    # when Build is called this code is invoked after it
}
```

When the build engine preprocesses tasks the task *Build* is transformed into a
task which is equivalent to this:

```powershell
task Build BeforeBuild, <original task jobs>, AfterBuild
```

## Incremental tasks

Other task parameters `Inputs`, `Outputs`, and the switch `Partial` are used in
order to define incremental and partial incremental tasks. These techniques are
described in here:

- [Incremental Tasks](Incremental-Tasks.md)
- [Partial Incremental Tasks](Partial-Incremental-Tasks.md)
