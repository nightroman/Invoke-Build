# Build script inheritance extends dot-sourcing

## Parameter "Extends"

Build script parameters `Extends` with `ValidateScript` attributes tell to
dot-source scripts and replace `Extends` with inherited base parameters.

Multiple and multilevel inheritance is supported, `ValidateScript` may specify
any number of scripts and these scripts may use `Extends` as well.

See examples of both inheritance trees below.

## Inheritance vs dot-sourcing

### Similarity

`Extends` dot-sources base scripts internally in the same way as manually
dot-sourced. This adds dot-sourced script tasks and parameter and script
variables to the current script scope.

### Differences

**Parameters**

- Inheritance

    Replaces `Extends` with base parameters, exposes them as dynamic parameters
    of `Invoke-Build`, passes input values in dot-sourced scripts.

- Dot-sourcing

    Requires manual base parameters duplication and propagation.

**`$BuildRoot`**

`$BuildRoot` is the automatic variable provided by IB.
Scripts may alter `$BuildRoot` on loading.
The default is usually `$PSScriptRoot`.

- Inheritance

    Each script in the inheritance tree has it own default or altered `$BuildRoot`.

- Dot-sourcing

    The default or altered `$BuildRoot` is the same for all scripts.

**Build blocks**

Scripts may define Enter/Exit blocks for build, script tasks, task jobs.

- Inheritance

    Each script in the inheritance tree has it own build blocks.

- Dot-sourcing

    Build blocks are the same for all scripts.

## Shared build script parameters

Same name parameters in different scripts in the inheritance tree are treated
as shared.

Ideally, shared parameters should be defined in all scripts using same types
and attributes, even same default values perhaps.

This is not always needed or possible. So the engine does not check anything.
On the inheritance tree traversal the last processed parameter with the same
name wins, i.e. becomes the root script dynamic parameter.

Examples below use the same `Configuration` and show some subtleties.

## Multilevel inheritance example

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

## Multiple inheritance example

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
