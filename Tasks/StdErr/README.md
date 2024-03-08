[#161]: https://github.com/nightroman/Invoke-Build/issues/161

## Dealing with standard error output

Invoking apps with standard error output may have issues in PowerShell.

PowerShell may convert app standard errors to its own non-terminating errors,
arguably unnecessarily. These errors become terminating if the error action
preference is `Stop`. Invoke-Build sets this preference to `Stop`.

As a result, without workarounds, builds may terminate unexpectedly on invoking
apps having standard error output. Another known issue is missing redirected
error output, see [#161].

### Workaround 1: relax the current error preference

This workaround works for normal PowerShell and Invoke-Build build scripts.
Just change `$ErrorActionPreference` to `Continue`, `SilentlyContinue`, or
`Ignore`, ideally in an extra script block (this is the case with `exec`),
so that the change is local for the script block:

```powershell
exec {
    $ErrorActionPreference = 'Continue'
    <invoke app with error output>
}
```

### Workaround 2: exec with relaxed error preference

In Invoke-Build scripts, another form of the same workaround is using `exec`
with relaxed `ErrorAction`:

```powershell
exec { <invoke app with error output> } -ErrorAction Continue
```

### Workaround 3: exec with -StdErr, v5.11.0

Use `exec -StdErr {...}` in order to handle standard errors differently:

- Automatically set `$ErrorActionPreference` to `Continue`.
- Capture standard output and errors and write as strings.
- If the exit code is failure, add errors to the message.

### Notes

The workarounds do not change how `exec` fails, it still fails depending on `$LastExitCode`.
But workarounds may affect another code in `exec` if there is anything but invoking an app.

Ideally and by design, each `exec` should invoke just one native command and nothing else.

### Tasks and tests

- [StdErr.build.ps1](StdErr.build.ps1) shows tasks with issues and workarounds.
- [StdErr.test.ps1](StdErr.test.ps1) tests the expected behaviour of these tasks.

### See also

- [#161]
