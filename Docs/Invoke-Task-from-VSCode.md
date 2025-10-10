# Invoke Task from VSCode

[Invoke-TaskFromVSCode.ps1]: https://www.powershellgallery.com/packages/Invoke-TaskFromVSCode
[#258]: https://github.com/PowerShell/PowerShellEditorServices/issues/258

[Invoke-TaskFromVSCode.ps1] invokes the current task of the current build script opened in VSCode.
It is invoked in the session (default) or in an external console (switch `Console`).
The current task is the task at the caret or above.

The script requires the VSCode PowerShell extension.

Configure `launch.json` or the global `launch` setting so that <kbd>F5</kbd> invokes the current task.
See [Debugging Tips](Debugging-Tips.md) for the example.
This is probably the simplest way of using the script: edit a task, press <kbd>F5</kbd>, the task is invoked.
If you have set some breakpoints then they break into the debugger when hit, otherwise the task just works.

Alternatively, you can invoke the script directly from the integrated console
or register it as one of `PowerShell.ShowAdditionalCommands` and choose it
there.

How to register commands. Create or open your VSCode profile (see `$profile`)
and add these commands

```powershell
Register-EditorCommand -Name IB1 -DisplayName 'Invoke task' -ScriptBlock {
    Invoke-TaskFromVSCode.ps1 | Out-Host
}

Register-EditorCommand -Name IB2 -DisplayName 'Invoke task in console' -SuppressOutput -ScriptBlock {
    Invoke-TaskFromVSCode.ps1 -Console
}
```

## Hotkeys

Consider adding to `keybindings.json`.

```json
{ "key": "ctrl+k i", "command": "PowerShell.ShowAdditionalCommands" },
```

## Settings

Consider adding to `settings.json`.

```json
"powershell.integratedConsole.showOnStartup": true,
```
