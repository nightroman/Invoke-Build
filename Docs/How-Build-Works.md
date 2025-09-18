# How Build Works

Invoke-Build invokes a build script, the default or specified by the parameter
`File`, with specified tasks and script parameters. The script declares its
parameters, sets variables, and defines at least one `task`.

Then Invoke-Build invokes tasks as follows:

1) Tasks specified by the parameter `Task` are invoked. If the parameter is not
specified or it is null, empty, or equal to "." then the "." task is invoked if
it is defined, otherwise the first added task is invoked.

2) The task parameter `If` is checked. If it is present and evaluates to false
then the task is skipped. The task still may be invoked later if it is called
again and `If` is defined as a script block which gets true that time.

3) The task jobs are invoked, that is referenced tasks and own scripts in the
specified order. The jobs are the original jobs defined by the parameter `Jobs`
and task references added by other tasks using `Before` and `After`. `Before`
jobs are inserted before the first script job. `After` jobs are added to the
end.

4) Before the first script block is invoked, the inputs and outputs from the
parameters `Inputs` and `Outputs` are evaluated and compared. If they are not
specified or outputs are out-of-date then all script blocks are invoked.
Otherwise script blocks are skipped, only referenced tasks are invoked.

The `$ErrorActionPreference` for each build script is set to `Stop`, otherwise
it is too easy to miss errors that should normally stop the build. Scripts may
change it at the script level once for all their tasks. But it is safer to keep
it and specify relaxed error actions for some commands.

Before any script code is invoked, i.e. a script itself, task jobs, conditions,
inputs, outputs, and blocks, the current location is set to `$BuildRoot` which
is by default the build script directory. This is very useful for accessing
other files by relative paths, including invocation of external scripts.

As soon as a task gets invoked and succeeds or fails, its contribution to the
current build is over, the task itself and its parts are never invoked again.
Code that may have to be invoked more than once should be defined as a
function, not a task. This function is called by tasks when needed.

If a task throws an exception or writes a terminating error then the whole
build fails unless the task is referenced as safe (`?TaskName`) by the
calling task and other tasks having a chance to be invoked.
The same convention works for task names in command lines.

In addition to tasks, build scripts may define special script blocks which
are invoked as described below:

- `Enter-Build {}` - before the first task
- `Exit-Build {}` - after the last task
- `Enter-BuildTask {}` - before each task
- `Exit-BuildTask {}` - after each task
- `Enter-BuildJob {}` - before each task action
- `Exit-BuildJob {}` - after each task action
- `Set-BuildHeader {param($Path)}` - on writing task headers
- `Set-BuildFooter {param($Path)}` - on writing task footers
