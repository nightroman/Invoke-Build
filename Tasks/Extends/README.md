# Build script inheritance

> How build script inheritance works and extends dot-sourcing.

- [Special parameter "Extends"](#special-parameter-extends)
- [Inheritance vs dot-sourcing](#inheritance-vs-dot-sourcing)
- [Shared build parameters](#shared-build-parameters)
- [Extending with prefix](#extending-with-prefix)
- [Build roots](#build-roots)
- [Examples](#examples)
    - [Building FarNet Showcase](#building-farnet-showcase)
    - [Multilevel inheritance](#multilevel-inheritance-example)
    - [Multiple inheritance](#multiple-inheritance-example)
    - [Renamed tasks](#renamed-tasks-example)

## Special parameter "Extends"

The build script parameter `Extends` with `ValidateScript` tells to
dot-source base scripts, replace `Extends` with base parameters, and
optionally rename base tasks with prefixes.

Multiple and multilevel inheritance is supported, `ValidateScript` may specify
any number of scripts and these scripts may use `Extends` recursively.

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

See [Build roots](#build-roots) for more.

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

## Extending with prefix

Scripts in the inheritance tree are expected to have tasks with same names,
e.g. `Build`, `Clean`, `Test`, etc. Tasks may be renamed with prefixes, to
avoid collisions or for clarity.

In order to rename inherited tasks with a custom prefix, `ValidateScript` of
`Extends` should return the script path with this prefix separated by `::`.

For example, the path `"main::.\src\1.build.ps1"` tells to extend the script
`.\src\1.build.ps1` and rename its tasks using the prefix `main::`, so that
the original task `Build` becomes `main::Build`.

### Not renamed tasks

**Already added tasks**

A task `X` is not renamed on adding if another task named `X` is already added
(another script with `X` is extended without a prefix). In this case the new
task `X` redefines the old.

> [!NOTE]
> Extending without a prefix is not recommended as such, unless a script is
designed as a common tasks library.

**Tasks with prefixes**

Tasks with `::` in names are not renamed. The idea is having some tasks with
known stable names, regardless of extending their script with a prefix or not.

> [!NOTE]
> This is yet another way to design a script as a common task library, to name
its tasks with some prefix right away.

**The default task**

The dot-task (default) is not renamed. When several scripts add dot-tasks, each
new redefines old, so that the last added dot-task becomes the build default.

"Redefined task" messages are omitted for dot-tasks, these tasks are expected
to be redefined.

> [!NOTE]
> Avoid referencing dot-tasks by other tasks. Default tasks should be treated as
volatile.

## Build roots

Each script in the inheritance tree has it own default `$BuildRoot`. The engine
sets this location current before invoking tasks, jobs, build blocks. Scripts
may alter the default build root during loading by the top level script code.

Some base scripts may need to set their `$BuildRoot` to one of the extended.
In order to support this, the engine provides the variable `$BuildRoots`, in
addition to `$BuildRoot`. Unlike always available `$BuildRoot`, `$BuildRoots`
exists on loading only.

`$BuildRoots` is an array of extended script roots:

- `$BuildRoots[0]` is `$BuildRoot` of the current script.
- `$BuildRoots[1]` is `$BuildRoot` of the first extended script, if any.
- ...
- `$BuildRoots[-1]` is `$BuildRoot` of the root script, which is invoked.

## Examples

### Building FarNet Showcase

[Building FarNet Showcase]: https://github.com/nightroman/Invoke-Build/wiki/Building-FarNet-Showcase

See [Building FarNet Showcase] for the real and complex example of using
inheritance features like multilevel and multiple inheritance, renaming
tasks with prefixes, visualising build graphs with task clusters, etc.

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

The parameter `Configuration` is defined in `Base.build.ps1` (default "Debug")
and `More.build.ps1` (default "Release"). The last definition becomes the final
parameter, so that the default "Release" takes over in this case.

The default dot-task of `Base.build.ps1` is redefined in `Test.build.ps1`.
The usual build message "Redefined task ..." is omitted for dot-tasks.

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
