# Build script inheritance

> How build script inheritance works and extends dot-sourcing.

- [Special parameter "Extends"](#special-parameter-extends)
- [Inheritance vs dot-sourcing](#inheritance-vs-dot-sourcing)
- [Shared build parameters](#shared-build-parameters)
- [Renamed build tasks](#renamed-build-tasks)
- [Examples](#examples)
    - [Multilevel inheritance](#multilevel-inheritance-example)
    - [Multiple inheritance](#multiple-inheritance-example)
    - [Renamed tasks](#renamed-tasks-example)

## Special parameter "Extends"

The build script parameter `Extends` with `ValidateScript` attribute tells to
dot-source scripts, replace `Extends` with base parameters, and optionally
rename base tasks with a custom prefix.

Multiple and multilevel inheritance is supported, `ValidateScript` may specify
any number of scripts and these scripts may use `Extends` recursively.

See examples of both inheritance trees below.

## Inheritance vs dot-sourcing

### Similarity

`Extends` tells to dot-source base scripts internally in the same way as
manually dot-sourced. This adds dot-sourced script tasks and variables
including parameters to the build script scope.

### Differences

**Parameters**

- Inheritance

    Automatically replaces `Extends` with base parameters, exposes them as
    dynamic parameters of `Invoke-Build`, passes values in dot-sourced scripts.

- Dot-sourcing

    Requires manual management of base parameters, either by duplication and
    passing or by setting script variables discovered with `property` calls.

**`$BuildRoot`**

`$BuildRoot` is the automatic variable provided by the engine.
Scripts may alter `$BuildRoot` on loading.
The default is usually `$PSScriptRoot`.

- Inheritance

    Each script in the inheritance tree has it own default or altered `$BuildRoot`.

- Dot-sourcing

    The default or altered `$BuildRoot` is the same for all scripts.

**Build blocks**

Scripts may define Enter / Exit blocks for build, tasks, jobs.

- Inheritance

    Each script in the inheritance tree has its own build blocks.

- Dot-sourcing

    Build blocks are the same for all scripts.

## Shared build parameters

Same name parameters in different scripts in the inheritance tree are treated
as shared.

Ideally, shared parameters should be defined in all scripts using same types
and attributes, maybe even same default values, to avoid runtime confusions.

Yet this is not always needed or possible. The engine does not check anything.
On the inheritance tree traversal the last processed parameter with the same
name wins, i.e. becomes the root script dynamic parameter.

Examples below use the same parameter `Configuration` and show subtleties.

## Renamed build tasks

Build scripts in the inheritance tree are expected to have tasks with same
names, e.g. `Build`, `Clean`, `Test`, etc. Unlike script parameters, tasks
cannot be "shared". But they may be optionally renamed.

In order to rename inherited tasks with a custom prefix, `ValidateScript` of
`Extends` should return the script path with this prefix separated by `::`.

For example, the path `"main::.\src\.build.ps1"` tells to extend the script
`.\src\.build.ps1` and rename its tasks using the prefix `main::`, so that
the original task `Build` becomes `main::Build`.

## Examples

### Multilevel inheritance example

[Multilevel](Multilevel) shows multilevel inheritance:

- `Test.build.ps1`
    - `More.build.ps1`
        - `Base.build.ps1`

**Test.build.ps1**

```powershell
param(
    # Replaced with parameters from "Base.build.ps1" and "More.build.ps1" recursively.
    [ValidateScript({"More\More.build.ps1"})]
    $Extends,

    # Own parameters.
    $Test1,
    $Test2 = 'test2'
)

# Own task.
task TestTask1 MoreTask1, {
    ...
}

# Redefined dot.
task . TestTask1
```

After resolving and removing `Extends`:

```powershell
param(
    # from "Base.build.ps1" (but "Release" comes from "More.build.ps1")
    $Configuration = "Release",
    $Base1,
    $Base2 = 'base2'

    # from "More.build.ps1"
    $More1,
    $More2 = 'more2'

    # from "Test.build.ps1"
    $Test1,
    $Test2 = 'test2'
)

# from "Base.build.ps1"
task BaseTask1 {
    ...
}
task . BaseTask1

# from "More.build.ps1"
task MoreTask1 BaseTask1, {
    ...
}

# from "Test.build.ps1"
task TestTask1 MoreTask1, {
    ...
}
task . TestTask1
```

**Redefined task**

The default dot-task of `Base.build.ps1` is redefined in `Test.build.ps1`.
The usual build message "Redefined task ..." is omitted because dot-tasks
are expected to be redefined.

"Redefined task ..." messages would still show for other redefined tasks
because they may be redefined accidentally.

**Shared parameter**

Parameter `Configuration` is defined in `Base.build.ps1` (defaut value "Debug")
and `More.build.ps1` (default value "Release").

The second definition becomes the final shared parameter, so that the default
value "Release" takes over in this case.

### Multiple inheritance example

[Multiple](Multiple) shows multiple inheritance:

- `Test.build.ps1`
    - `Base.build.ps1`
    - `More.build.ps1`

**Test.build.ps1**

```powershell
param(
    # Replaced with parameters from "Base.build.ps1" and "More.build.ps1".
    [ValidateScript({"..\Base\Base.build.ps1", "More\More.build.ps1"})]
    $Extends,

    # Own parameters.
    $Test1,
    $Test2 = 'test2'
)

# Own task.
task TestTask1 BaseTask1, MoreTask1, {
    ...
}
```

After resolving and removing `Extends`:

```powershell
param(
    # from "Base.build.ps1" (but "Release" comes from "More.build.ps1")
    $Configuration = "Release",
    $Base1,
    $Base2 = 'base2'

    # from "More.build.ps1"
    $More1,
    $More2 = 'more2'

    # from "Test.build.ps1"
    $Test1,
    $Test2 = 'test2'
)

# from "Base.build.ps1"
task BaseTask1 {
    ...
}
task . BaseTask1

# from "More.build.ps1"
task MoreTask1 {
    ...
}

# from "Test.build.ps1"
task TestTask1 BaseTask1, MoreTask1, {
    ...
}
```

### Renamed tasks example

[Prefixes](Prefixes) shows renamed tasks:

- `Test.build.ps1`
    - `Base.build.ps1`
    - `More.build.ps1`

The root script `Test.build.ps1` extends `Base.build.ps1` and `More.build.ps1`, all three have the task `Build`.
The root `Build` is supposed to call two inherited `Build` tasks and then run its own build job.

**Test.build.ps1**

```powershell
param(
    # Specifies inherited task prefixes, "one::" and "two::" for Base and More.
    [ValidateScript({"one::Base\Base.build.ps1", "two::More\More.build.ps1"})]
    $Extends
)

# References base tasks using prefixes.
task Build one::Build, two::Build, {
    "Test $Configuration"
}
```

After resolving and removing `Extends`:

```powershell
param(
    # from base scripts
    $Configuration
)

# from "Base.build.ps1"
task one::Build {
    "Base $Configuration"
}

# from "More.build.ps1"
task two::Build {
    "More $Configuration"
}

# from "Test.build.ps1"
task Build one::Build, two::Build, {
    "Test $Configuration"
}
```
