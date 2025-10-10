# Debugging Tips

[Debug-Error.ps1]: https://www.powershellgallery.com/packages/Debug-Error
[#258]: https://github.com/PowerShell/PowerShellEditorServices/issues/258

The tips are focused on debugging and troubleshooting in VSCode with the PowerShell extension.
Some tips are not VSCode specific.

## Build script debugging with launch.json

In the DEBUG panel click `Open 'launch.json'` and add configurations

```json
      {
        "type": "PowerShell",
        "request": "launch",
        "name": "IB Default Task",
        "script": "Invoke-Build",
        "args": [
          ".",
          "${file}"
        ],
        "cwd": "${workspaceRoot}"
      },
      {
        "type": "PowerShell",
        "request": "launch",
        "name": "IB Current Task",
        "script": "Invoke-TaskFromVSCode.ps1",
        "args": [],
        "cwd": "${workspaceRoot}"
      },
      {
        "type": "PowerShell",
        "request": "launch",
        "name": "PS Interactive Session",
        "cwd": "${workspaceRoot}"
      },
```

The first starts debugging of the current build script with the default task.

The second starts debugging of the current build script with the current task
by [Invoke Task from VSCode](Invoke-Task-from-VSCode.md).

The third opens PowerShell Extension terminal where you can type commands, including Invoke-Build.
It is needed for running several specified tasks or with not default parameters.
Or you may call the registered command `Invoke current task`, see [Invoke Task from VSCode](Invoke-Task-from-VSCode.md).

In the DEBUG panel, select one of `IB Default Task`, `IB Current Task`, `PS Interactive Session`.
Ensure the current build script is saved and set breakpoints by <kbd>F9</kbd>.
Start debugging by <kbd>F5</kbd>.
With `PS Interactive Session`, type a command or call the registered `Invoke current task`.

## Break on terminating errors

Use the little handy script [Debug-Error.ps1] in order to break into the debugger on terminating errors automatically.
See its help for more.

Consider limiting the scope of errors to scripts of interest, e.g. build scripts.
That is, use the command

```powershell
Debug-Error MyProject.build.ps1
```

The above breaks exactly in `MyProject.build.ps1` and avoids unwanted breaks in the build engine.
Errors are caught and re-thrown by the engine code and breaks there are unlikely useful.

## Other techniques

Invoke-Build scripts are usual PowerShell code and the standard PowerShell debugging tools work.
Set some custom breakpoints by calling `Set-PSBreakpoint` in the PowerShell extension terminal.

To break when a function is called

```powershell
Set-PSBreakpoint -Command MyBuildFunction
```

To break when a variable is read or written

```powershell
Set-PSBreakpoint -Variable MyBuildVariable [-Mode Read | Write | ReadWrite]
```
