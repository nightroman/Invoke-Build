# SubCases

Inspired by [#222](https://github.com/nightroman/Invoke-Build/issues/222).

**File structure**

- `root.build.ps1`
- `case1`
    - `case1.tasks.ps1`
- `case2`
    - `case2.tasks.ps1`

**Build parameters**

```powershell
param(
    [Parameter(Mandatory=1)]
    [string]$Case
    ,
    [string]$Configuration = 'Release'
)
```

In this example the parameter `$Case` is mandatory and the specified case script is always dot-sourced.

But the script could be designed with an optional `$Case` or using the default case.

Examples:

```powershell
# case1, default task with default parameters
Invoke-Build -Case case1

# case2, common task with custom parameters
Invoke-Build root1 -Case case2 -Configuration Debug
```

**Some features**

Let's use the term "assets" for script scope variables and functions.

- `Invoke-Build` without `-File` works in the root and child folders.
- The root script parameters and assets are available for case tasks.
- The case specific assets are available for common root tasks.
- Cases may change root assets defined before dot-sourcing.
- See features in action shown by [.test.ps1](.test.ps1).
