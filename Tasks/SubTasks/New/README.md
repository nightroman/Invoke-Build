# Build script inheritance

> Arguably better alternative to [Old](../Old) "Sub tasks technique".

`root.build.ps1` extends `build.build.ps1` and `deploy.build.ps1` using this notation:

```powershell
param(
    [ValidateScript({ "build::src/build.build.ps1", "deploy::deploy/deploy.build.ps1" })]
    $Extends,
    ...
)
```

Results:

- The root script gets base script parameters as its own dynamic.
- All base tasks are added with prefixes avoiding name conflicts.

The old example uses tedious ceremonies in order to get similar results.

## See Also

- [Extends](../../Extends)
