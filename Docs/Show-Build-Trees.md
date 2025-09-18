# Show Build Trees

[Show-BuildTree.ps1]: https://github.com/nightroman/Invoke-Build/blob/main/Show-BuildTree.ps1

The script [Show-BuildTree.ps1] visualizes specified build task trees as
indented text with brief task details.

## Example

This command invoked for the build script of this project

    Show-BuildTree NuGet

shows the following task tree

    NuGet # Make the NuGet package.
        Version # Set $script:Version.
            {}
        Package # Make the package directory z\tools for NuGet.
            ConvertMarkdown # Convert markdown files to HTML files (using MarkdownDeep).
                {}
            Help # Build the PowerShell help file.
                {}
            GitStatus # Warn about not empty git status if .git exists.
                {}
            {}
        {}
