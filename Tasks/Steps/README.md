# Tasks as steps, interactive, persistent, ...

> How to run all defined tasks together, with optional interactive confirmations.\
> How to run these steps persistent, with checkpoints for resuming interrupted.

The example [Release.build.ps1](Release.build.ps1) is the script for releasing
`Invoke-Build`. It is not to run as a demo, use your own steps, any script with
several tasks.

Let's call build script tasks "steps" if they are supposed to be invoked all
together, in the order of adding. Steps may reference other steps (and alter
the sequence) but usually do not have to, the natural order is enough.

Why steps? Some task sequences are easier to compose and maintain this way.
One trivial scenario is testing, when each task is a test. Tests are meant
to be run all together at some point.

Another scenario is automated flows when steps require human interaction or
pauses, e.g. for checking step results or waiting for some external events.

In order to run "steps" use the pseudo task `*`:

```powershell
Invoke-Build *
```

## Dot-task to run steps

> How to add the default task to run steps as `Invoke-Build`

A bit hacky but effective, the dot-task may be the last (!) like this:

```powershell
# Synopsis: All tasks.
task . @(${*}.All.Keys)
```

A non-hacky way using the fact that pseudo task `*` excludes `.`:

```powershell
# Synopsis: All tasks.
task . {
    Invoke-Build *
}
```

## Persistent steps with checkpoints

- Steps are tasks invoked in the order of their definition.
- Persistence is archived by using `Build-Checkpoint`.
- All tasks are invoked as the pseudo task `*`.
- Some tasks use interactive confirmations.

Users may interrupt the build on confirmations and resume later.

The low ceremony way to invoke this:

```powershell
# from script directory
Build-Checkpoint

# from different locations
Build-Checkpoint ...\Release.build.ps1
```

The checkpoint is `Release.build.ps1.clixml` in the script directory. If it
does not exists, a new persistent build starts. Otherwise, the build resumes
with this checkpoint.

If the default dot-task is needed for doing exactly this and maybe for more
options to be added later:

```powershell
# Synopsis: All tasks, persistent.
task . {
    Build-Checkpoint "$BuildFile.clixml" @{Task = '*'; File = $BuildFile} -Auto
}
```

## See Also

- [Confirm](../Confirm)
- [Persistent Builds](https://github.com/nightroman/Invoke-Build/blob/main/Docs/Persistent-Builds.md)
