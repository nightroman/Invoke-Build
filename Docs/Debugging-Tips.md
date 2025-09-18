# Debugging Tips

[Debug-Error.ps1]: https://www.powershellgallery.com/packages/Debug-Error
[#258]: https://github.com/PowerShell/PowerShellEditorServices/issues/258

The tips are focused on debugging and troubleshooting in VSCode with the
PowerShell extension. Some tips are not VSCode specific.

## Build script debugging with launch.json

In the DEBUG panel click *Open 'launch.json'* and add two entries

```json
{
    "type": "PowerShell",
    "request": "launch",
    "name": "Invoke-Build Default Task",
    "script": "Invoke-Build",
    "args": [".", "${file}"],
    "cwd": "${workspaceRoot}"
},
{
    "type": "PowerShell",
    "request": "launch",
    "name": "Invoke-Build Current Task",
    "script": "Invoke-TaskFromVSCode",
    "args": [],
    "cwd": "${workspaceRoot}"
},
```

The first starts debugging of the current build script with the default task.
The second starts debugging of the current build script with the current task by [Invoke Task from VSCode](Invoke-Task-from-VSCode.md).

In the DEBUG panel, ensure the current configuration is *"Invoke-Build Default Task"* or *"Invoke-Build Current Task"*.
Open your build script and set the required breakpoints by <kbd>F9</kbd>.
Start debugging by <kbd>F5</kbd>.

## Build script debugging without launch.json

Debugging of tasks without *launch.json* is possible as well, e.g. to start and
debug the build from the command line with several tasks or specific parameters.

Open your build script and set the required breakpoints by <kbd>F9</kbd>.

Currently, VSCode editor breakpoints are not always synchronised with the
PowerShell breakpoints. To work around this, use this debug launcher

```json
{
    "type": "PowerShell",
    "request": "launch",
    "name": "PowerShell Current File",
    "script": "${file}",
    "args": [],
    "cwd": "${workspaceRoot}"
},
```

and hit <kbd>F5</kbd> as to debug the script directly. This fails with an error
like *"The term 'task' is not recognized..."* but makes breakpoints ready.

Save changes and then type Invoke-Build commands in the PowerShell extension
terminal or invoke the current task from the script in the editor using the
registered command, see [Invoke Task from VSCode](Invoke-Task-from-VSCode.md).

As a result, you break into the debugger when breakpoints are hit during the
build and the debugger works as usual in this scenario.

## Break on terminating errors

Use the little handy script [Debug-Error.ps1] in order to break into the
debugger on terminating errors automatically. See its help for the details.

It is recommended to limit the scope of errors to the scripts of interest,
i.e. the build script. That is, use the command

```powershell
Debug-Error MyProject.build.ps1
```

in order to enable stops exactly in *MyProject.build.ps1* and skip related
noise stops in the build engine. Errors are caught and re-thrown several
times in the engine code and you do not want to stop there on each.

## Other techniques

Invoke-Build scripts are usual PowerShell code and the standard PowerShell
debugging tools are available. Set some interesting breakpoints by calling
`Set-PSBreakpoint` from the PowerShell extension terminal.

To break when a function is called

```powershell
Set-PSBreakpoint -Command MyBuildFunction
```

To break when a variable is read or written

```powershell
Set-PSBreakpoint -Variable MyBuildVariable [-Mode Read | Write | ReadWrite]
```
