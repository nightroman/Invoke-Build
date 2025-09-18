# DEV Public Functions

## The engine state and build results `${*}`

### Public build results

---

    All = [System.Collections.Specialized.OrderedDictionary]([System.StringComparer]::OrdinalIgnoreCase)

All tasks added by the build script except redefined.

---

    Tasks = [System.Collections.Generic.List[object]]@()

Tasks invoked in the build.

---

    Errors = [System.Collections.Generic.List[object]]@()

Errors collected in the build.

---

    Warnings = [System.Collections.Generic.List[object]]@()

Warnings collected in the build.

---

    Redefined = @()

Redefined task objects removed from `All`.

---

    Doubles = @()

Collected potentially always skipped double referenced tasks [#82](https://github.com/nightroman/Invoke-Build/issues/82).
They are checked when the build starts.

---

    Started = [DateTime]::Now

Build start time.

---

    Elapsed = $null

Build duration, `[timespan]`.

---

    Error = 'Invalid arguments.'

The build failure error.
It is null when the build completes.

The default is a surrogate string error available in the build result on invalid arguments.
The actual error should be caught by `try/catch`, this one is for simple checks like `if ($Result.Error) ...`.

Why is this surrogate? Because IB cannot handle all invalid arguments anyway.
For example, invalid script parameters cause errors in PowerShell, not in IB.
Thus, `try/catch` must be used in order to handle all possible errors.

### Private engine state

---

    Task = $null

Null or the current task.

---

    File

Either a build script path or a script block to be invoked.
Added in 3.6.0, [#78](https://github.com/nightroman/Invoke-Build/issues/78).

---

    Safe = $PSBoundParameters['Safe']
    Summary = $PSBoundParameters['Summary']

Original build parameters.
IB removes parameter variables, to avoid conflicts with user variables.

---

    CD = $OriginalLocation = *Path

The original current location restored in `finally`.
`$OriginalLocation` is exposed for build scripts.
But `${*}.CD` is used internally for safety.

---

    DP = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

Dynamic parameters, i.e. all build script parameters.

---

    BB = [System.Collections.Generic.List[object]]@()

Inherited build scripts data list starting from base to invoked.
`.File`: script path or block.
`.SP`: script parameters specified on invoking
// these parameters are sent to the dot-sourced build scripts
// they are stored in checkpoint files by `Build-Checkpoint`.

---

    B1 = $null

On scripts loading, the current build data to be captured in task objects. It is then used by tasks for restoring build roots and invoking build blocks.

---

    P = ...

Null or the parent engine state object.
Tasks, errors, and warnings from the current state are appended to the parent in `finally`.

---

    A = 1

Abort state.
1: build is aborted.
0: build is started.

If `A` is 1 in `finally` then the build is aborted before tasks.
It is used just in order to print a distinctive ABORTED message.
Why not just use `B`? Because `B = 2` in `catch` and this is not enough to tell ABORTED or FAILED.

---

    B = 0

Build state.
0: build not started.
1: build completed.
2: build failed.

If `B` is 0 we do not print the header and footer.

---

    Q = 0

Query mode.
0: normal build mode.
True: IB is called with `?` or `??`.

---

    H = @{}

Help synopsis cache used by `Get-BuildSynopsis`.

---

    Header = if ($_) {$_.Header} else {{Write-Build 11 "Task $($args[0])"}}
    Footer = if ($_) {$_.Footer} else {{Write-Build 11 "Done $($args[0]) $($Task.Elapsed)"}}

Task headers and footers. On nested builds inherit them from callers.

---

    Data = @{}

External data set by `Set-BuildData`.
Used by `Build-Checkpoint` ("Checkpoint.Export", "Checkpoint.Import").

---

    XBuild = $null
    XCheck = $null

External hooks injected via the parameter `Result`.
`XBuild` is called after `Enter-Build` before invoking tasks.
`XCheck` is called after `XBuild` before invoking tasks and after each completed task.

## `$BuildRoot`, the special variable

Unlike other build variables, this one is supposed to be set in special cases.
A user may assign a custom path and it will be maintained current by the engine.

IB normalizes and tests `$BuildRoot` after loading scripts.

IB used to make `$BuildRoot` constant [#95](https://github.com/nightroman/Invoke-Build/issues/95).
This is not the case in v5.14 but scripts are not supposed to change this variable.

Q: Why not using a special function `Set-BuildRoot`?

A: Because the current way is simple, flexible, and works in older versions.
A function may look confusing like something designed for several calls.
But the build root is either not changed or changed just once.

## `Add-BuildTask` (alias `task`)

[#171](https://github.com/nightroman/Invoke-Build/issues/171)
Do not add tasks after loading, i.e. when `${*}.A -ne 0`.

[#137](https://github.com/nightroman/Invoke-Build/issues/137)
Why we use the magic number (-9) as the default of the parameter `If` instead of the original `$true`.

v3.3.8
Before adding the task to the list, check for the existing and move such a task to `Redefined` in build results.
When the build starts, write gray messages about each task in `Redefined`.

Errors

* Cannot add tasks - if a task is added after loading.
* Invalid task name - if a task name starts with `?`.
* Invalid job - if a job is not string or scriptblock.

## `Get-BuildFile`

- `$Path`: full directory path
- `$Here`: tells to skip parents
- Output: full file path or null

It is used by the engine and helpers.

Loop:

```powershell
# $f = get files like *.build.ps1, array of full paths
# if there is exactly one then return it
if (($f = [System.IO.Directory]::GetFiles($Path, '*.build.ps1')).Length -eq 1) {return $f}

# if $f is not empty (2+ items) then sort and return the first
if ($f) {return $($f | Sort-Object)[0]}

# at this point $f is empty, i.e. we did not find a build script
# try to get it by the hook, if any, then move to the parent folder

# get the hook command ($null or some): $c = $env:InvokeBuildGetFile
# if $c is not empty then invoke it: $f = & $c $Path
# if the result $f is not empty then return $f
if (($c = $env:InvokeBuildGetFile) -and ($f = & $c $Path)) {return $f}

# done?
if ($Here) {return}

# repeat with the parent path, if not empty, otherwise return
$Path = Split-Path $Path
```

## `Get-BuildProperty` (alias `property`)

**2017-04-10 v3.3.4**

See [#60](https://github.com/nightroman/Invoke-Build/issues/60)

Interestingly, `[Environment]::GetEnvironmentVariable` gets null for an existing but empty env var.
Anyway, it is fine to check as we do: `!($_ = [Environment]::GetEnvironmentVariable($Name))`.
Null and empty are both treated as undefined.

**NB**

Replaced `$ExecutionContext.SessionState.PSVariable.GetValue($Name)`
with faster `$PSCmdlet.GetVariableValue($Name)`.

## `Get-BuildSynopsis` gets task synopsis

- It is used on `ib ?`
- It is suitable for making more informative task output.
- *Show-BuildTree.ps1* uses it as well via dot-sourcing IB.

Plot:

```powershell
# get the task file name
$f = ($I = $Task.InvocationInfo).ScriptName

# create the cache of file text lines (T) and comment tokens (C)
if (!($d = $Hash[$f])) {
    $Hash[$f] = $d = @{T = Get-Content -LiteralPath $f; C = @{}}
    foreach($_ in [System.Management.Automation.PSParser]::Tokenize($d.T, [ref]$null)) {
        if ($_.Type -eq 15) {$d.C[$_.EndLine] = $_.Content}
    }
}

# starting from the line before the task and going backwards, do
for($n = $I.ScriptLineNumber; --$n -ge 1) {

    # if it is a comment
    if ($c = $d.C[$n]) {
        # if it has a synopsis, return it
        if ($c -match '(?m)^\s*#*\s*Synopsis\s*:(.*)') {return $Matches[1].Trim()}}

    # else continue if it is an empty line
    elseif ($d.T[$n - 1].Trim()) {break}
}
```

## `Remove-BuildItem` (alias `remove`)

It is the robust alternative to `Remove-Item ... -Force -Recurse -ErrorAction Ignore`,
see [#123](https://github.com/nightroman/Invoke-Build/issues/123)

## `Resolve-MSBuild` (*Resolve-MSBuild.ps1*)

Script functions are used in order to mock on testing.

Do not always `Import-Module VSSetup`, check if it is loaded first. Reasons:

1. It may be loaded from a not standard location. `psake` has such a request from a user.
2. VSSetup used to have problems with loading twice (due to a global const variable).

**Resolve-MSBuild and Preview**

2017 Professional Preview (support many preview editions)

    C:\Program Files (x86)\Microsoft Visual Studio\Preview\Professional\MSBuild\15.0\...

2019 Community Preview (support the only preview edition)

    C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview\MSBuild\Current\..

Tempting change

    $folders = switch($Version) {
        * {if ($Prerelease) {'2019\Preview\*', 'Preview\*'} else {'2019\*', '2017\*'}}
        '16.0' {if ($Prerelease) {'2019\Preview\*'} else {'2019\*'}}
        default {if ($Prerelease) {'Preview\*'} else {'2017\*'}}
    }

But why? Per `#107`, the goal is to find Preview if it is the only installed.
For 2017 the change was needed and done. It is still valid for 2017.
For 2019 no extra change is needed, "Preview" is found as one of the "editions" and treated as "others".

**Resolve-MSBuild Issues:**

- [#55 Cannot resolve '15.0' with MSBuild version 15](https://github.com/nightroman/Invoke-Build/issues/55)
- [#57 Added ability to resolve path to Build Tools installed in non-standard directory](https://github.com/nightroman/Invoke-Build/pull/57)
- [#77 Wrong MSBUILD selected](https://github.com/nightroman/Invoke-Build/issues/77) Introduced explicit product precedence.
- [#84 Resolve MSBuild 15 to ..\amd64\MSBuild.exe on x64](https://github.com/nightroman/Invoke-Build/issues/84)
- [#85 Add ability to choose which MSBuild architecture to use](https://github.com/nightroman/Invoke-Build/issues/85)
- [#107 Add ability to use MSBuild from Visual Studio Preview](https://github.com/nightroman/Invoke-Build/pull/107)
- [#122 Resolve-MSBuild does not return the latest version installed.](https://github.com/nightroman/Invoke-Build/issues/122)
- [#148 Resolve-MSBuild no longer locates '15.0 x86'](https://github.com/nightroman/Invoke-Build/issues/148)
- [#216 Do not wrap internal errors in Resolve-MSBuild](https://github.com/nightroman/Invoke-Build/issues/216)

## `Use-BuildAlias` (alias `use`)

`Get-Item <path>\*` is useful but very slow. `Get-ChildItem <path>` is faster.

Replaced `Convert-Path (Resolve-Path -LiteralPath $Path -ErrorAction Stop)`
with `*Path` + `[System.IO.Directory]::Exists`. The old does not work in paths with `[ ]`.

## `Write-Build` writes with colors, if possible

v5.9.5 `Write-Build` splits the text into lines and calls the internal `*Write`.

**Why split into lines**

1. To make ANSI rendering working in terminals like GitHub actions.
2. To avoid potentially inconsistent `\r \n \r\n` in the input text.

#### `*Write`

There are 3 alternative functions.

(1) With PS 7.2+ and ANSI `*Write` uses escape sequences for rendering.

(2) `*Write` is defined to use `$Host.UI` for setting terminal colors.
`try..finally` is used to avoid issues on interruptions like `Ctrl-C`.

(3) Then a test of (2) is performed `$null = *Write 0`. If it throws then we
assume the host is "bad" and define `*Write` as literal output of the input.

**Known "bad" hosts**

The *Default Host* (created by `[PowerShell]::Create()`) or *ServerRemoteHost*
(background jobs) have UI and RawUI defined. At the same time RawUI throws on
setting colors ("not supported").

The *ServerRemoteHost*. Used in older PowerShell and removed later.

**Write-Host (1.2.2) and Write-Warning (1.4.1)**

v1.2.2 With 'Default Host' `Write-Host` is defined as empty, disabled. Do not
turn it to a text writer, i.e. do not redefine, this breaks code that returns
data and writes some extra info using `Write-Host`.

**NOTE** `Write-Host` dropped.

1.4.1 Ditto about `Write-Warning`

## `Write-Warning` wraps and extends warnings

    function Write-Warning([Parameter()]$Message)

It replaces the native cmdlet and provides the same parameters as the main
native parameters. Common native parameters are ignored.

This function extends warning information and makes build analysis easier,
either with the build result object or just with the log. When the build is
over, collected warnings are printed together with task names and script paths.

When `Write-Warning` is called the native warning is still written as

    $PSCmdlet.WriteWarning($Message)

In addition to this, we collect warning information in the result list.
The stored warning object properties

    Message = $Message # warning message
    File = $BuildFile  # current build file
    Task = ${*}.Task   # current build task or null
    InvocationInfo     # where Write-Warning is called

## Invoke-TaskFromVSCode.ps1

    trap {$PSCmdlet.ThrowTerminatingError($_)}

-- is bad for throw in tasks, errors point to `Invoke-TaskFromVSCode`, not to `throw`.

    try {
    } catch {if ($_.InvocationInfo.ScriptName -eq $MyInvocation.ScriptName) {$PSCmdlet.ThrowTerminatingError($_)} throw}

-- is bad for running from `x.txt`, errors point to "useless" internal code inside `Invoke-TaskFromVSCode`.

Lesson: this works fine:

    try {
    } catch {if ($_.InvocationInfo.ScriptName -like '*Invoke-TaskFromVSCode.ps1') {$PSCmdlet.ThrowTerminatingError($_)} throw}

Perhaps VSCode paths are formatted differently, so that `$_.InvocationInfo.ScriptName -eq $MyInvocation.ScriptName` is not reliable.

## Set-BuildHeader and Set-BuildFooter

Originally they used to set task headers and footers just for the current script.

Starting from v5.7.1 IB inherits headers and footers from the parent build, if
any. The new behaviour looks more useful and natural, the top caller decides
how the output looks.

More prominent headers and footers make sense in CI scenarios like GitHub
actions. IB colors may not work in such builds and it may be difficult to
visually separate output of different tasks in the logs.
