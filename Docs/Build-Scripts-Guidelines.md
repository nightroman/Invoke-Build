# Build Scripts Guidelines

Here are some guidelines based on Invoke-Build scripts here and there.
They are not rules, scripts may work fine even if they do not follow.

## Use Enter-Build or check $WhatIf for initialization

Scripts often use some initialization code invoked before tasks. If it is just
setting a few script scope variables then it is fine right in the script body.

But for heavier jobs like loading modules or changing things outside consider
using `Enter-Build`, the special block invoked before tasks. It is invoked in
the script scope, as if its code is there.

Alternatively, check the build variable `$WhatIf`. If it is false then invoke
your initialization code.

Why? Because build scripts are not always invoked for running tasks.
They may be invoked for getting task information or code completion.

**Example with `Enter-Build`**

```powershell
Enter-Build {
    'Prepare for tasks...'
}

task Task1 {
    'Doing Task1...'
}
```

**Example with `$WhatIf`**

```powershell
if (!$WhatIf) {
    'Prepare for tasks...'
}

task Task1 {
    'Doing Task1...'
}
```

## $BuildRoot, $PSScriptRoot, $OriginalLocation

For getting the build directory, use the predefined variable `$BuildRoot`. The
engine sets the current location to `$BuildRoot` before invoking task jobs and
other build blocks.

By default `$BuildRoot` is the build script directory. You may change it in the
beginning of your script. Then all tasks may rely on the new custom build root
maintained current by the engine.

On the other hand, if you need the directory of the current script regardless
of `$BuildRoot` then use the PowerShell variable `$PSScriptRoot`.

Use the predefined variable `$OriginalLocation` in order to get the location
which was current on invoking the build script. Note that this location is
restored as current after the build.

## Set-Location instead of Push and Pop

Consider using `Set-Location` instead of `Push-Location` and `Pop-Location`.
The engine takes care of restoring the location to `$BuildRoot` for tasks.

Push-and-pop makes sense only if the original location is needed in the same
task later. But the original location of a task is always `$BuildRoot`, so
that `Set-Location $BuildRoot` will do the same (but safer, see later).

DO

```powershell
task MyTask {
    Set-Location ...
    ...
}
```

DO NOT

```powershell
task MyTask {
    Push-Location ...
    ...
    Pop-Location
}
```

Besides, the above code is not safe. If it fails before `Pop-Location`
then the location stack remains not clean. The safe code should be:

```powershell
task MyTask {
    Push-Location ...
    try {
        ...
    }
    finally {
        Pop-Location
    }
}
```

## Throw vs. Write-Error

Consider using `throw` instead of `Write-Error` in task code. `throw` results
in error information pointing to the error line. This is useful for analysis
and jumping to the source, e.g. from VSCode output with <kbd>Ctrl+Click</kbd>.

In contrast, `Write-Error` points to the caller code. In tasks it is some build
engine line, not useful for error analysis.

DO

```powershell
task MyTask {
    if (...) {
        throw 'Something is wrong'
    }
}
```

DO NOT

```powershell
task MyTask {
    if (...) {
        Write-Error 'Something is wrong'
    }
}
```

CAVEAT

In functions called from tasks, `Write-Error` is fine and even preferable if
errors should point to the calling task.

## Write-Host alternatives

Avoid `Write-Host` unless you deliberately target some messages for console
only and do not need them in the redirected output, e.g. in build log files.

Use `print` (`Write-Build`) for color messages not lost on redirection.
For plain messages from tasks output text directly or by `Write-Output`.

DO

```powershell
task MyTask {
    'Message 1'
    Write-Output 'Message 2'
    print 10 'Green message'
    Write-Build Green 'Green message'
}
```

Avoid in tasks

```powershell
task MyTask {
    Write-Host 'Message 1'
    Write-Host 'Message 2'
    Write-Host 'Green message' -ForegroundColor Green
}
```

CAVEAT

Only tasks and `Enter/Exit-*` blocks may output log-like messages. Functions
with their own returned data cannot. This is not about Invoke-Build, this is
PowerShell. Thus, `Write-Host` in functions may be reasonable.

## Avoid task parameter Before

Unless there are reasons like inability to modify some tasks, avoid using the
parameter `Before` in order to set task relations. The normal and clear way
to define task relations is using the parameter `Jobs`, with the name often
omitted:

**Prefer**

```powershell
task Build Restore, {
    ...
}
```

**Avoid**

```powershell
task Restore -Before Build {
    ...
}
```

As for the similar parameter `After`, if you find the below notation somewhat
odd or not clear, especially when `Build` script block has many lines:

```powershell
task Build {

    ...

}, Test
```

then instead use `Test` defined with `-After`:

```powershell
task Test -After Build {
    ...
}
```
