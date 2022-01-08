# Problematic `:` in dynamic `-Param:Value`

Using the notation `-Param:Value` with dynamic parameters may cause issues.

It is not clear what the culprit is, PowerShell or Invoke-Build.

## Example

[Test-1-bug.ps1](Test-1-bug.ps1) calls the build script with the dynamic
parameter specified as `-Configuration:Release` and two tasks specified after,
`clean` and `build`.

```powershell
Invoke-Build -Configuration:Release clean, build
```

As a result, only the `clean` task is invoked, i.e. actually passed in the
build engine. The task `build` is "lost".

## Workarounds

(1) Do not use the notation `-Param:Value` with dynamic parameters.
Example: [Test-2-ok.ps1](Test-2-ok.ps1)

```powershell
Invoke-Build -Configuration Release clean, build
```

(2) Do not omit named parameter names.
Example: [Test-3-ok.ps1](Test-3-ok.ps1)

```powershell
Invoke-Build -Configuration:Release -Task clean, build
```

(3) Use named parameters before dynamic.
Example: [Test-4-ok.ps1](Test-4-ok.ps1)

```powershell
Invoke-Build clean, build -Configuration:Release
```

## See also

- [DynamicParamSwitch](../DynamicParamSwitch/README.md)
