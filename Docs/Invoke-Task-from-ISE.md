# Invoke Task from ISE

[Invoke-TaskFromISE.ps1]: https://www.powershellgallery.com/packages/Invoke-TaskFromISE

The script [Invoke-TaskFromISE.ps1] invokes the current task from the build
script being edited in PowerShell ISE. It is invoked either in ISE or in
PowerShell console.

The current task is the task found at the caret line or above. If nothing is
found, e.g. the caret is in the beginning of the file, then the default task is
invoked. The current file is saved if it is modified.

If the build fails when the task is invoked in ISE and the error location is in
the same build script then the caret is automatically moved to the error
position.

This script may be called directly from the console pane. But it is easier to
use associated with key shortcuts. For example, in order to invoke it in ISE by
<kbd>Ctrl+Shift+T</kbd> and in console by <kbd>Ctrl+Shift+B</kbd> add the
following lines to the ISE profile:

```powershell
# Invoke task in ISE by Invoke-Build.ps1
$null = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(
'Invoke Task in ISE', {Invoke-TaskFromISE.ps1}, 'Ctrl+Shift+T')

# Invoke task in console by Invoke-Build.ps1
$null = $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add(
'Invoke Task in Console', {Invoke-TaskFromISE.ps1 -Console}, 'Ctrl+Shift+B')
```

These commands assume that *Invoke-TaskFromISE.ps1* is in the path.
If this is not the case then specify the full script path there.

To get the ISE profile path, type `$profile` in the console pane:

    PS> $profile
    C:\Users\...\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1
