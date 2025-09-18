# Comparison with MSBuild

Invoke-Build scripts are designed to be conceptually similar to MSBuild. They
are PowerShell, not XML, and they use different tools. But build concepts and
script structure are very similar.

| MSBuild | Invoke-Build |
| ------- | ------------ |
| Default project `*proj` | Default script `*.build.ps1` |
| `DefaultTargets` | The `.` task or the first task |
| `InitialTargets` | Script code and `Enter-Build` |
| Properties | Script and environment variables |
| Import | Dot-source or invoke |
| Target | Task |
| Condition | `-If` |
| `Inputs`, `Outputs` | `-Inputs`, `-Outputs`, `-Partial` |
| `DependsOnTargets` | `-Jobs`, referenced tasks |
| Tasks | `-Jobs`, script blocks |
| `AfterTargets`, `BeforeTargets` | `-After`, `-Before` |

MSBuild targets consist of calls to built-in or external tools. Invoke-Build
tasks consist of PowerShell script blocks. Unlike MSBuild, Invoke-Build does
not provide numerous tools for scripts, PowerShell does this.

Invoke-Build task jobs combine two MSBuild features: referenced targets and own
target tasks. The parameter `Jobs` is a list of task references (analogue of
`DependsOnTargets`) and script blocks (analogue of MSBuild tasks). Thus, jobs
define classic MSBuild scenarios (referenced tasks first, own scripts second)
and new scenarios with referenced tasks after or even between script jobs.

Invoke-Build "properties" are usual PowerShell script variables and parameters,
just like MSBuild properties defined in XML scripts (variables) and properties
that come from command lines (parameters). MSBuild also deals with environment
variables using the same syntax. In contrast, Invoke-Build scripts either use
environment variables as `$env:Name` or get them by the helper `property`.

MSBuild allows ignoring some errors and triggering actions on errors. Some
Invoke-Build tasks are allowed to fail without breaking the build and then
downstream tasks may analyse these errors.

Invoke-Build allows definition of new tasks with specific features and new
parameters, not necessarily designed for build scenarios. E.g. `check` for
check-lists, `repeat` for schedules, `test` for testing, and etc. MSBuild
presumably does not directly support definition of new targets.

## DefaultTargets and InitialTargets

The exact equivalent of MSBuild's `DefaultTargets` is the special Invoke-Build
task `.` (dot), the default task. All its referenced tasks are default tasks.

The partial equivalent of MSBuild's `InitialTargets` is Invoke-Build script
scope code and the `Enter-Build` block. Consider using `Enter-Build` if the
code does anything significant.

The exact equivalent of MSBuild's `InitialTargets` would be yet another task
with a special name. But the practice shows that this is not really needed.

## AfterTargets and BeforeTargets with Condition

`AfterTargets` and `BeforeTargets` of MSBuild targets with `Condition` are
always invoked, even if the condition is false. In contract, `After` and
`Before` of Invoke-Build tasks with `If` are not invoked if the condition is
false. In other words, these two Invoke-Build scripts are identical, unlike
equivalent MSBuild scripts:

```powershell
# script 1
task Task1 {...}
task Task2 -If {...} Task1, {...}

# script 2
task Task1 -Before Task2 {...}
task Task2 -If {...} {...}
```

See the task `condition_and_targets` in [Acknowledged.build.ps1](https://github.com/nightroman/Invoke-Build/blob/main/Tests/Acknowledged.build.ps1).
