# Build Failures

Build failures are caused by invalid arguments (e.g. missing tasks, scripts),
invalid scripts (e.g. missing task references), and runtime errors in scripts
and tasks.

## How to deal with build failures

Use one of the techniques below or you may miss some failures.

### PowerShell script

If you do not want to catch errors and just want the calling script to stop on
build failures then do

```powershell
$ErrorActionPreference = 'Stop'
Invoke-Build ...

# Build completed, do other stuff.
# This is not called on failures.
...
```

If you want to catch a build error and proceed further depending on it then do

```powershell
try {
    Invoke-Build ...

    # Build completed
    ...
}
catch {
    # Build FAILED, $_ is the error
    ...
}
```

**Notes**

Do not use `Invoke-Build ... -ErrorAction ...`, it is not designed to work as
one may expect.

Do not use `Invoke-Build ... -Safe` in order to suppress all build failures.
`Safe` works for errors in started builds. Invalid calls are not covered.

The only reliable way to handle all errors consistently is `try/catch`.
Invalid arguments cause errors in PowerShell, not Invoke-Build.
Ditto if the command Invoke-Build itself is not available.

### Batch script

If you call Invoke-Build by *powershell* then check for an exit code. It is 0
if a build completes. Other exit codes are for failures.

Example batch file:

```batchfile
powershell -NoProfile -Command Invoke-Build ...
if ERRORLEVEL 0 goto OK

echo Build FAILED.
exit /b %ERRORLEVEL%

:OK
echo Build completed.
exit /b 0
```

### MSBuild script

You can call Invoke-Build from MSBuild using the task *Exec*. Nothing special
is needed for failure detection, this task fails when Invoke-Build fails (due
to non zero exit code).

```xml
<Exec Command='powershell -NoProfile -Command Invoke-Build ...'/>
```

Or you can use *PostBuildEvent* in Visual Studio projects (MSBuild scripts).
Nothing special is needed for failure detection, too. The post build event
fails if Invoke-Build fails.

```xml
<PropertyGroup>
    <PostBuildEvent>powershell -NoProfile -Command Invoke-Build ...</PostBuildEvent>
    <RunPostBuildEvent>OnBuildSuccess</RunPostBuildEvent>
</PropertyGroup>
```

## How to fail in scripts

There are several ways to cause failures with more or less important
differences in information about error code location.

### assert and equals

Use `assert` in order to check for a condition and fail with the default or a
custom message if a condition is not evaluated to true.

```powershell
task Example {
    assert (...) "Something is wrong."
}
```

In test-like tasks consider using `equals X Y` instead of `assert (X -eq Y)`.
It is easier to type, it avoids subtle PowerShell conversions, and its error
message shows different object values and types.

Errors from `assert` and `equals` emphasize failures caused by unexpected
conditions. Each error points to the line of code where `assert` or `equals`
fails.

### throw

Use standard PowerShell `throw` in order to throw an error from task code

```powershell
task Example {
    throw "Something is wrong."
}
```

Each error points to the line of code where it is thrown.

### Write-Error

Do not use `Write-Error` in tasks directly. It works but error source
information is not useful, it points to some engine code, useless for
troubleshooting.

But `Write-Error` can be useful in a function shared between tasks if such
errors should point to a task which calls a function and causes its failure.
