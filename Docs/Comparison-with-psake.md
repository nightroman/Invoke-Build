# Comparison with psake

Invoke-Build was inspired by [psake](https://github.com/psake/psake).
It inherited the best parts, redesigned some others, added many new.
As a result, it is easier to use, more robust, and build scripts are
closer to vanilla PowerShell.

See [Convert-psake](Convert-psake.md) for converting *psake* scripts to *Invoke-Build*.

## Engine differences

- Invoke-Build is implemented as a script, not a module function. As a result,
  each build is invoked in its script scope. Tasks naturally share build script
  parameters, variables, functions, and aliases and can explicitly specify the
  build scope by the standard prefix *script*.

- Build script parameters are defined using the usual `param` syntax. They are
  passed directly in Invoke-Build as if they are its own. Code completion of
  parameters works, too.

- Invoke-Build maintains its state in its script scope. When a build completes
  all data and service functions are gone. Environment variables like *PATH*
  are not changed, even temporarily.

- As many other build tools, Invoke-Build supports incremental tasks with
  inputs processed or skipped depending on their timestamps compared with
  outputs.

- Several build scripts can be invoked in parallel in the same process by
  *Build-Parallel*. The engine is prepared to work in hosts like *Default
  Host* (runspaces) or *ServerRemoteHost* (jobs).

- Invoke-Build supports persistent builds for long running or interactive
  processes with expected interruptions. Such builds may be resumed at a
  stopped task. See *Build-Checkpoint*.

- Invoke-Build can invoke all tasks (`*`) and all tasks in all `*.test.ps1`
  files (`**`). This is normally used for invoking tests defined as tasks.

- For build analysis Invoke-Build can optionally return result tasks, errors,
  warnings, and other details about the current and nested builds.

- Invoke-Build resolves default tasks and scripts differently. The default task
  is the task named '.', if any, or the first added. The default script is the
  first `*.build.ps1` in `Sort-Object` order. The default script is searched in
  the current location and its parents.

- Invoke-Build does not use the concept of a single *Framework* because scripts
  may use tools from several frameworks. Instead, it provides the command `use`
  which helps to create aliases for various tools.

- Invoke-Build allows task redefinitions with messages about each case. MSBuild
  allows target redefinitions and PowerShell allows function redefinitions.

- `TaskSetup` and `TaskTearDown` are replaced with `Enter-*` and `Exit-*` for
  the build, each task, and each job. Each `Exit-*` is always called if its
  pair `Enter-*` is called.

- Configurations are not used. Custom task headers and footers are defined in
  build scripts by `Set-BuildHeader` and `Set-BuildFooters`. Blocks `Enter-*`
  and `Exit-*` may write some header/footer like information as well.

- Invoke-Build takes care of hiding its variables from user code. Otherwise
  exposed variables in some cases affect user code unexpectedly.

- Invoke-Build allows definition of new tasks with specific features and new
  parameters. E.g. `check` for check-lists, `repeat` for periodically invoked,
  `retry` for retrying failed tasks, ...

## Task differences

- New parameters
    - `Inputs`, `Outputs`, and `Partial` for incremental tasks.
    - `Before` and `After` for alteration of other tasks.
    - `Data`, `Done`, and `Source` for extensions.

- Parameters `Depends`, `PreAction`, `Action`, and `PostAction` are replaced
  with `Jobs`, the list of referenced tasks and own actions. Note that tasks
  may be specified after actions, somewhat unique feature among build tools.

- `PostCondition` is not used. The similar code is an `assert` in an extra
  action, thanks to `Jobs`: `task ... {main action}, {assert (...)}`.

- The parameter `If` is used instead of `PreCondition`. In addition to a script
  block evaluated on task invocation it accepts objects, results of expressions
  evaluated on adding tasks. Expressions may catch potential issues earlier.

- `ContinueOnError` is not used. A caller of a task decides if its failure is
  safe and uses "?": `task DependsOnFaulty ?FaultyTask, ...`. This also works
  for task names in build command lines, another unique feature.

- `RequiredVariables` is not used. Instead, commands `requires` and `property`
  are used where appropriate in scripts and tasks.

- The documentation comment `# Synopsis: ...` is used instead of `Description`.
  It is easier to compose and read and avoids data irrelevant for builds. Help
  task `?` returns objects, not text. Output can be formatted as required.

- `Alias` is not used but alias tasks are possible: `task MyAlias MyTaskName`.
