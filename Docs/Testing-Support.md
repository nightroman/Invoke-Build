# Testing Support

Invoke-Build is useful for testing, especially in PowerShell projects.
It is easy to maintain PowerShell tests as build tasks. The following
supportive features are offered right away:

- `assert` and `equals` are must have features.
- Tests start, end, output, and duration logging.
- Tests are invoked individually or by sets (`*, **`).
- Tests may have dependencies and hierarchical structure.
- Tests have easy access to files using relative file paths.
- Tests are invoked once even if referenced by multiple parents.
- Build results can be obtained for detailed analysis and reports.

Invoke-Build is not specifically designed to be a test system. But for testing
relatively small projects it does the job very well with minimum ceremonies.
Invoke-Build itself has 600+ test tasks.

## Batch tasks * and **

The special tasks `*` and `**` are used in order to make invocation of tests
easy. The following command invokes all tasks (tests) defined in the script:

```powershell
Invoke-Build * Smoke.test.ps1
```

The task `**` invokes `*` for all files `*.test.ps1` found in the directory
*Tests* and its subdirectories:

```powershell
Invoke-Build ** Tests
```

When the switch `Safe` is used together with `**` then build failures stop
current test scripts, not the whole testing, invocation of remaining test
scripts continues:

```powershell
Invoke-Build ** -Safe
```

`Safe` is often used together with `Summary` or `Result`. The switch `Summary`
tells to print task records including errors after the build. The parameter
`Result` is used in order to get build data for further detailed analysis
and reports. See [Build Analysis](Build-Analysis.md)

With `*` and `**` there is no need to call tests individually or register them
for testing. As soon as a test task is added to a script, it gets invoked when
a script is invoked with `*`. Note that dependencies are taken into account,
`*` invokes task trees starting from roots. Without dependencies tasks are
invoked in their natural order in scripts.

## Examples in projects

The list of some projects where tests are build tasks tested by Invoke-Build.
The links are project directories with tests.

- [Invoke-Build](https://github.com/nightroman/Invoke-Build/tree/main/Tests)
- [Mdbc](https://github.com/nightroman/Mdbc/tree/main/Tests)
- [PowerShelf](https://github.com/nightroman/PowerShelf/tree/main/Demo)
- [SplitPipeline](https://github.com/nightroman/SplitPipeline/tree/main/Tests)
- [PowerShellTraps](https://github.com/nightroman/PowerShellTraps)
