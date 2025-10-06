# Show Build Trees

[Show-BuildTree.ps1]: https://github.com/nightroman/Invoke-Build/blob/main/Show-BuildTree.ps1

The script [Show-BuildTree.ps1] visualizes specified build task trees as
indented text with brief task details.

## Example

For this project build script, this command

```text
Show-BuildTree pushNuGet
```

shows this task tree

```text
pushNuGet # Push NuGet package.
    nuget # Make the NuGet package.
        module # Make the module folder.
            version # Set $Script:Version.
                {}
            markdown # Convert markdown files to HTML.
                {}
            help # Build the PowerShell help file.
                {}
            {}
        {}
    {}
```
