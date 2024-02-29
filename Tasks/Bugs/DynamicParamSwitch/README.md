# Dynamic switch parameter issue

[Stack Overflow Q/A]: https://stackoverflow.com/q/25560038/323582

According to this [Stack Overflow Q/A] dynamic switch parameters may
"incorrectly" consume named parameters specified immediately after.

It is the PowerShell "feature" and script authors should deal with it.

## Example

[Test-1-bug.ps1](Test-1-bug.ps1) calls the build script with the dynamic switch
`Extra` and two tasks specified after, `clean` and `build`.

```powershell
Invoke-Build -Extra clean, build
```

As a result, only the `clean` task is invoked, i.e. actually passed in the
build engine. The task `build` is "lost".

## Workarounds

(1) Do not omit named parameter names.
Example: [Test-2-ok.ps1](Test-2-ok.ps1)

```powershell
Invoke-Build -Extra -Task clean, build
```

(2) Use named parameters before dynamic switches.
Example: [Test-3-ok.ps1](Test-3-ok.ps1)

```powershell
Invoke-Build clean, build -Extra
```

## See also

- [DynamicParamColon](../DynamicParamColon)
