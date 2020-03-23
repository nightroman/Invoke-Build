## Dealing with standard error output

Invoking apps with standard error output may have issues in PowerShell and Invoke-Build.

PowerShell converts app standard errors to its own non-terminating errors,
arguably unnecessarily. These errors become terminating if the error action
preference is `Stop`. Note that Invoke-Build sets this preference to `Stop`.

As a result, without workarounds, builds may terminate unexpectedly on invoking
apps having standard error output. Another known issue is missing redirected
error output, see [#161].

### Workaround 1: relax the current error preference

This workaround works for normal PowerShell and Invoke-Build build scripts.
Just change `$ErrorActionPreference` to `Continue`, `SilentlyContinue`, or
`Ignore`, ideally in an extra script block, so that the change does not affect
other code:

```powershell
& {
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

This option does not change how `exec` fails, it still fails depending on the
`$LASTEXITCODE` after the invocation. But keep in mind, this option may affect
another code in the `exec` block, if there is something before or after
invoking an app or in its command parameter expressions.

### Tasks and tests

The script [.build.ps1](.build.ps1) shows the tasks with issues and workarounds.
The script [.test.ps1](.test.ps1) tests the expected behaviour of these tasks.

- **Problem**

    Shows the problem, the build fails on standard error output.

- **Workaround**

    `exec {...} -ErrorAction Continue` works around the problem.

- **Workaround2**

    The workaround does not affect how `exec` fails on app exit codes.

### See also

- [#161]

[#161]: https://github.com/nightroman/Invoke-Build/issues/161
