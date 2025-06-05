# Confirm-Build example

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
The script [Confirm.build.ps1](Confirm.build.ps1) shows tasks with confirmations.

## Use cases

Traditional build scripts unlikely need any interaction, they are not designed
for this. But `Invoke-Build` scripts are effectively just scripts with tasks.
What tasks do is up to authors, including interaction.

`Confirm-Build` was designed for interactive "steps" where steps are tasks.

## See Also

- [Steps](../Steps)
- [Release.build.ps1](../Steps/Release.build.ps1) - real script with `Confirm-Build`
