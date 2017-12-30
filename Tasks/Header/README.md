
## How to print more task details in task headers

Invoke-Build default task headers are printed as

    Task /<path>

where `<path>` is a task name with its parent/calling tasks.

The command `Set-BuildHeader` is used in order to use a different format and
print additional information like task synopses, locations in build scripts,
start times, and etc. Colored lines are written by `Write-Build`.

Synopses are defined as the special comments `# Synopsis: ...` before tasks.
Each synopsis is one line of text with short task description. It is normally
used for getting task help by `Invoke-Build ?`. The sample shows how to use
task synopses in task headers.

Printed task locations may be useful in VSCode output window. They work like
links, <kbd>Ctrl+Click</kbd> opens the clicked location in the editor.
The sample shows how to use task locations in task headers.

See the sample script [Header.build.ps1](Header.build.ps1).
