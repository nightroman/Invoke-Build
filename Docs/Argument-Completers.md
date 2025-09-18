# Argument Completers

[Invoke-Build.ArgumentCompleters.ps1]: https://github.com/nightroman/Invoke-Build/blob/main/Invoke-Build.ArgumentCompleters.ps1

PowerShell provides powerful code completion tools and extensions.
One of the useful features is custom argument completers.

The script [Invoke-Build.ArgumentCompleters.ps1] registers `Invoke-Build`
completers. You may install it from PSGallery (included to the path
automatically but may require a fresh session):

````powershell
Install-Script Invoke-Build.ArgumentCompleters
````

or download and choose your own location, consider included to the path:

````powershell
Save-Script Invoke-Build.ArgumentCompleters -Path .
````

Completers are defined for two `Invoke-Build` parameters:

- `Task` - Task names are completed from the default or specified build script.
- `File` - For `**` gets directories otherwise directories and *.ps1* files.

Note that completion of dynamic parameters coming from a build script also
works, with or without custom completers. This feature is built-in.

## How to use after installing

**Standard way**

Invoke installed or downloaded completers, e.g. in your PowerShell profile
(see the variable `$PROFILE`):

```
Invoke-Build.ArgumentCompleters.ps1
```

**Advanced way**

Use [TabExpansion2.ps1](https://www.powershellgallery.com/packages/TabExpansion2)
as the extension of the native completion engine, with some handy features.

Put `Invoke-Build.ArgumentCompleters.ps1` to the path in order to be loaded
automatically on the first completion.

## Consider GuiCompletion

For even better completion experience in the console you may use [GuiCompletion](https://github.com/nightroman/PS-GuiCompletion).\
(Not just for Invoke-Build, any PowerShell code completion.)

Install the module from PSGallery by this command:

```powershell
Install-Module GuiCompletion
```

Then enable it in PowerShell sessions, for example in your profile (see the variable `$PROFILE`):

```powershell
Install-GuiCompletion          # with the default `Ctrl+Spacebar`
Install-GuiCompletion -Key Tab # with the traditional `Tab`
```

## Use Enter-Build or $WhatIf in build scripts

This is recommended for all build scripts but especially for scripts designed
for task name completion and other introspections.

Any significant script level code should be wrapped by `Enter-Build {...}` or
`if (!$WhatIf) {...}`. Otherwise the code is invoked on task name completion
and commands like `Invoke-Build ?` and `Invoke-Build -WhatIf` may have not
desired effects.
