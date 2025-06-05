# Tasks as steps, interactive, persistent, ...

> How to run all defined tasks together, with confirmations in this example.\
> How to make this step run persistent with checkpoints for resuming stopped.

The example script [Release.build.ps1](Release.build.ps1) is used for real for
releasing `Invoke-Build`. It is just for code browsing, it is not supposed to
be used as a demo to run.

Let's call "steps" all tasks in a build script invoked together, in the natural
order of added tasks. Steps may reference other steps but usually do not have
to, the order is enough.

Why steps? Some task sequences are easier to compose and maintain this way.
One trivial scenario is testing, when each task is a test. Tests are meant
to be run all together, at some point.

Another typical class is automated flows where steps require human
interaction or simply pauses for checking some step results.

In order to run "steps" use the pseudo task `*`:

```powershell
Invoke-Build *
```

The next reading is about cases when `*` is not enough.

## Dot-task to run steps

> How to add the default dot-task to run steps.

A bit hacky but concise and effective way.
Define the default dot-task as *the last (!)* like this:

```powershell
# Synopsis: All previous tasks.
task . @(${*}.All.Keys)
```

Now, in order to invoke all other tasks, actual steps, invoke:

```powershell
Invoke-Build
```

A non-hacky way might be this:

```powershell
# Synopsis: All tasks but this.
task . -If {'.' -eq $BuildTask} {
    Invoke-Build *
}
```

## Dot-task to run persistent steps

> How to add the default dot-task to run steps with checkpoints.

```powershell
# Synopsis: All tasks, persistent.
task . -If {'.' -eq $BuildTask} {
    Build-Checkpoint -Auto z.clixml @{Task='*'}
}
```

In this scenario:

- Steps are tasks organised in the order of their execution.
- Persistence  archived by using `Build-Checkpoint.ps1`.
- All tasks are invoked internally by pseudo task `*`.
- Some tasks are designed with confirmations.

As a result, at the confirmation points a user may interrupt the build for
whatever reason and resume it later from the saved checkpoint file.

## See Also

- [Confirm](../Confirm)
- [Persistent Builds](https://github.com/nightroman/Invoke-Build/wiki/Persistent-Builds)
