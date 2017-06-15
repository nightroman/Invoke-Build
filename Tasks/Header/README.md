
## How to print more task details in task headers

Invoke-Build default task headers are very simple:

    Task /<path>

It is possible to print additional information in task headers, for example,
task synopses, locations in build scripts, start times, and etc. Colored
lines are supported by `Write-Build`.

Synopses are defined as the special comments `# Synopsis: ...` preceding tasks.
Each synopsis is one line of text with short task description. It is normally
used for getting task help by `Invoke-Build ?`. The sample shows how to get
task synopses for something else, e.g. custom task headers.

Printed task locations are especially useful in VSCode output window. They work
like links, i.e. <kbd>Ctrl+Click</kbd> opens the clicked location in the editor.
The sample shows how to get task locations.

See the sample script [Header.build.ps1](Header.build.ps1).
