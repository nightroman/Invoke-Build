# Custom task headers and footers

Invoke-Build default task headers are printed as

    Task /<task-path>

and footers as

    Done /<task-path> <elapsed-time>

where `<task-path>` is a task name with its parent (calling) tasks.

The commands `Set-BuildHeader` and `Set-BuildFooter` are used in order to set a
different format and print additional information like task synopses, locations
in build scripts, start times, and etc. Colored lines are written by
`Write-Build`.

Synopses are defined as the special comments `# Synopsis: ...` before tasks.
Each synopsis is one line of text with short task description. It is normally
used for getting task help by `Invoke-Build ?`. The sample shows how to use
task synopses in task headers.

Printed task locations may be useful in VSCode output window. They work like
links, <kbd>Ctrl+Click</kbd> opens the clicked location in the editor.
The sample shows how to use task locations in task headers.

Scripts:

- [1.build.ps1](1.build.ps1) shows how to set custom headers and footers and typical useful data.
- [2.build.ps1](2.build.ps1) is called by the first script to show that headers and footers are inherited.

See also:

- [Color and formatting text in Azure DevOps Pipelines #205](https://github.com/nightroman/Invoke-Build/issues/205)
