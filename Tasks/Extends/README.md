# Build script inheritance extends dot-sourcing

## Parameter "Extends"

Build script parameters `Extends` with `ValidateScript` attributes tell to
dot-source scripts and replace `Extends` with inherited base parameters.

Multiple and multilevel inheritance is supported, `ValidateScript` may specify
any number of scripts and these scripts may use `Extends` as well.

See examples of both inheritance hierarchies below.

## Inheritance vs dot-sourcing

### Similarity

`Extends` dot-sources base scripts internally in the same way as manually dot-sourced.
This adds dot-sourced script tasks and parameter variables to the current script scope.

### Differences

**Parameters**

- Inheritance

    Replaces `Extends` with base parameters and propagates them on dot-sourcing.

- Dot-sourcing

    Requires manual base parameters duplication and propagation.

**`$BuildRoot`**

`$BuildRoot` is the automatic variable provided by IB.
Scripts may alter `$BuildRoot` on loading.
The default is usually `$PSScriptRoot`.

- Inheritance

    Each script in the inherited tree has it own default or altered `$BuildRoot`.

- Dot-sourcing

    The default or altered `$BuildRoot` is the same for all scripts.

**Build blocks**

Scripts may define Enter/Exit blocks for build, script tasks, task jobs.

- Inheritance

    Each script in the inherited tree has it own build blocks.

- Dot-sourcing

    Build blocks are the same for all scripts.

## Multilevel inheritance example

[Multilevel](Multilevel) shows multilevel inheritance:

- `Test.build.ps1`
    - `More\More.build.ps1`
        - `..\Base\Base.build.ps1`

**Test.build.ps1**

```powershell
param(
    # Replaced with parameters from "More.build.ps1" (and "Base.build.ps1", recursively).
    [ValidateScript({"More\More.build.ps1"})]
    $Extends,

    # Own parameters.
    $Test1,
    $Test2 = 'test2'
)

# Own task.
task TestTask1 MoreTask1, {
    "TestTask1 Base1=$Base1 Base2=$Base2 More1=$More1 More2=$More2 Test1=$Test1 Test2=$Test2"
}

# Redefine dot.
task . TestTask1
```

The original parameters and tasks are transformed (logically):

```powershell
param(
    # from "Base.build.ps1"
    $Base1,
    $Base2 = 'base2'

    # from "More.build.ps1"
    $More1,
    $More2 = 'more2'

    # own parameters
    $Test1,
    $Test2 = 'test2'
)

task BaseTask1 {
    "BaseTask1 Base1=$Base1 Base2=$Base2"
}

task . BaseTask1

task MoreTask1 BaseTask1, {
    "MoreTask1 Base1=$Base1 Base2=$Base2 More1=$More1 More2=$More2"
}

task TestTask1 MoreTask1, {
    "TestTask1 Base1=$Base1 Base2=$Base2 More1=$More1 More2=$More2 Test1=$Test1 Test2=$Test2"
}

task . TestTask1
```

**Redefined tasks**

Note, the default dot-task in `Base.build.ps1` is redefined in `Test.build.ps1`
and the usual semi-warning message "Redefined task ..." is omitted for this
special task.

These messages still show for other redefined tasks because they may be
redefined accidentally.

## Multiple inheritance example

[Multiple](Multiple) shows multiple inheritance:

- `Test.build.ps1`
    - `Base\Base.build.ps1`
    - `More\More.build.ps1`

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
    "TestTask1 Base1=$Base1 Base2=$Base2 More1=$More1 More2=$More2 Test1=$Test1 Test2=$Test2"
}
```

The original parameters and tasks are transformed (logically):

```powershell
param(
    # from "Base.build.ps1"
    $Base1,
    $Base2 = 'base2'

    # from "More.build.ps1"
    $More1,
    $More2 = 'more2'

    # own parameters
    $Test1,
    $Test2 = 'test2'
)

task BaseTask1 {
    "BaseTask1 Base1=$Base1 Base2=$Base2"
}

task . BaseTask1

task MoreTask1 {
    "MoreTask1 More1=$More1 More2=$More2"
}

task TestTask1 BaseTask1, MoreTask1, {
    "TestTask1 Base1=$Base1 Base2=$Base2 More1=$More1 More2=$More2 Test1=$Test1 Test2=$Test2"
}
```
