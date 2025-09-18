# VSCode Tips

VSCode with the PowerShell extension and Invoke-Build play very well together,
especially since the integrated PowerShell console (terminal) was introduced.
Here are some tips on how to integrate and use the tools.

The terminal is opened with the current location set to the workspace directory.
And the default build script (`MyProject.build.ps1`) is normally there. As a
result, you do not have to specify the script path on typing build commands.

Consider using the alias `ib` for `Invoke-Build` in order to reduce typing even
more. Namely, in your `Microsoft.VSCode_profile.ps1` set

```powershell
Set-Alias ib Invoke-Build
```

To get the path of `Microsoft.VSCode_profile.ps1`, type `$profile` in the
extension terminal (not regular PowerShell terminal).

Thus, normally only `ib` is typed and the task names. Note that task names may
be completed by <kbd>Tab</kbd> in the terminal.
See [Argument Completers](Argument-Completers.md)

In order to get information about the available tasks, type

```powershell
ib ?
```

If you want to invoke the current build task being composed in the editor use
the helper script `Invoke-TaskFromVSCode.ps1`. The current task is where the
caret is (or the default if the caret is before all tasks).
See [Invoke Task from VSCode](Invoke-Task-from-VSCode.md)

In the build script editor, when the caret is at `task` use <kbd>Shift+F12</kbd>
in order to show the task list, i.e. references to `task` in the code. Navigate
through tasks by clicks in the list.

Debugging and troubleshooting of build scripts seems to be very easy, even with
occasional hiccups (development of VSCode and the PowerShell extension is in
progress). See [Debugging Tips](Debugging-Tips.md)

When the build completes with errors, use the printed task or error information
in the terminal in order to jump to the point of problems in the editor. Namely,
point the mouse to a printed file path and <kbd>Ctrl+Click</kbd> in order to
follow the link.

You can invoke Invoke-Build in the current session as many times as you need.
Invoke-Build does not change anything in the session itself. When a build
finishes all used data and functions are gone. Keep in mind though that
invoked build scripts may change the session.

Finally, it is possible to bind your build script tasks to generated VSCode tasks.
See [Generate VSCode Tasks](Generate-VSCode-Tasks.md).
