# Confirm-Build sample

The function `Confirm-Build` is used for interactive confirmations in build
scripts. Unlike `$PSCmdlet.ShouldContinue()`, the function may be redefined,
for example to work quietly as "Yes" or "No".

`Confirm-Build` may be used for any block of code in a build script:

```powershell
if (Confirm-Build 'Do something?') {
    # Do something
    ...
}
```

But it is particularly useful for confirming tasks using `-If {...}` task blocks.
The script [Confirm.build.ps1](Confirm.build.ps1) demonstrates tasks with confirmations.

## About use cases

Traditional build scripts unlikely need any interaction, they are not designed
for this. But Invoke-Build scripts are effectively just scripts with tasks.
What tasks do is up to an author, including some interaction.

`Confirm-Build` and its predecessor `ask`-task (now retired) were designed for
interactive and persistent "steps" where some steps are manual and taking
unknown time. In this scenario:

- Steps are tasks organised in the order of their execution.
- Persistence is archived by using `Build-Checkpoint.ps1`.
- All tasks are invoked by using the special task `*`.
- Some tasks are designed with confirmations.

As a result, at the confirmation points a user may interrupt the build for
whatever reason and resume it later from the saved checkpoint.
