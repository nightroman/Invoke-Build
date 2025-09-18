# Persistent Builds

Long running or interactive workflows with expected interruptions can be
automated with persistent builds which allow resuming after interruptions.

## Starting persistent builds

In order to make a build persistent, i.e. run it with written checkpoints, use
the command `Build-Checkpoint` with a path to the checkpoint file. The file is
created before the first task and updated after each succeeded task. Then the
file is deleted if the build succeeds, otherwise it is preserved and supposed
to be used for resuming the build. The build resumes starting with the failed
or interrupted task.

For example, these commands start persistent builds:

```powershell
# with the default task and script
Build-Checkpoint temp.clixml

# with the specified tasks and script
Build-Checkpoint temp.clixml @{Task = 'Build', 'Clean'; File = '../Project.build.ps1'}
```

## Resuming persistent builds

In order to resume an interrupted build use `Build-Checkpoint` with the same
(existing) checkpoint file and the switch `Resume`. Primary build parameters
(`Task`, `File`, script parameters) are not needed because they are restored
from the checkpoint file and ignored in the command. Secondary parameters
(`Safe`, `Summary`, `Result`) are still relevant and may be changed.

In many cases, especially in interactive scenarios, just add `-Resume`
to the previous command which started the interrupted persistent build.

Example:

```powershell
Build-Checkpoint temp.clixml -Resume
```

## Invoking all tasks with checkpoints

> Ad hoc convention for low ceremony persistent step sequences.

Omitted or script `Checkpoint` tells to run ***all tasks*** with checkpoints:

```powershell
Build-Checkpoint
Build-Checkpoint Steps.build.ps1
```

The checkpoint path is the script path with added suffix `.clixml`.
The persistent build starts if the checkpoint does not exist, otherwise it
resumes from the existing checkpoint.

This notation is easy to remember and use interactively, unlike its formal full equivalent:

```powershell
Build-Checkpoint -Checkpoint "Steps.build.ps1.clixml" -Build @{Task = "*"; File = "Steps.build.ps1"} -Auto
```

## Preparing build scripts

Scripts which do not have state data shared by tasks, like script scope
variables, are often ready for persistent builds right away.

Scripts which use script scope variables can make these variables persistent
simply by declaring them as script parameters, even if they are not actually
used as parameters. Script parameters are saved and restored automatically.

> Use `[Parameter(DontShow=$true)]` to exclude parameters from completions.

If this is not enough then scripts may define export / import blocks for
maintaining build state persistence.

The export block is called before each task. It outputs data to be serialized.

The import block is called once on resuming. Its argument is deserialized data.
It is called in the script scope, so that for restoring script variables the
prefix `Script` is optional.

For example, a script uses two variables `$Version` and `$Archive` which are
calculated by the task *SetVariables*:

```powershell
# It is a good idea to declare them always, for Set-StrictMode or to hide
# existing in parent scopes and avoid serializing irrelevant data

$Version = $null
$Archive = $null

task SetVariables {
    $Script:Version = ...
    $Script:Archive = ...
}
```

Other tasks reference this task and use these variables assuming they are set.
If a persistent build is interrupted after *SetVariables* then on resuming the
variables will not be set for those tasks. Export / import blocks solve this:

```powershell
Set-BuildData Checkpoint.Export {
    $Version
    $Archive
}

Set-BuildData Checkpoint.Import {
    param($data)
    $Version, $Archive = $data
}
```

As mentioned before, in this particular case it is possible and perhaps better
to make `$Version` and `$Archive` persistent by declaring them as parameters:

```powershell
param(
    # actually used parameters
    $Platform,
    ...
    # variables for persistence
    [Parameter(DontShow=$true)]
    $Version,
    [Parameter(DontShow=$true)]
    $Archive
)
```

This is it, if there is nothing else to persist then custom export and import
are not needed, persistence of parameters is performed by the engine.

## Caution

- Think what the persistent build state is.
- Some data are not suitable for clixml export.
- Changes in stopped build scripts may cause incorrect resuming.
- Checkpoint files must not be used with different engine versions.
