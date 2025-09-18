# Convert-psake

[Convert-psake.ps1]: https://github.com/nightroman/Invoke-Build/blob/main/Convert-psake.ps1

You may convert your *psake* scripts to *Invoke-Build* scripts somewhat automatically by the script [Convert-psake.ps1].
The scripts is not included to the packages. Get it from the repository or download by this PowerShell command:

```powershell
# download Convert-psake.ps1 to the current location
Invoke-WebRequest https://raw.githubusercontent.com/nightroman/Invoke-Build/main/Convert-psake.ps1 -OutFile Convert-psake.ps1
```

Having downloaded the script, run it on your `my.psake.ps1` in order to convert to `my.build.ps1`:

```powershell
# convert my.psake.ps1 to my.build.ps1
Convert-psake.ps1 my.psake.ps1 | Set-Content my.build.ps1
```

For simple scripts, the conversion might be complete.
Open the result `*.build.ps1` file in a text editor.
Review and modify the TODO sections as described.
Happy building!

See also [Comparison with psake](Comparison-with-psake.md) for more details about the differences.
