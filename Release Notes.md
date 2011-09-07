Invoke-Build - Release Notes
============================

## v1.0.6

**Breaking change:** `Use-BuildFramework` (alias `framework`) is transformed
into `Use-BuildAlias` (alias `use`). For .NET frameworks it works as it used
to, only the command names have to be updated. But now it can be used with any
tool directory, not necessarily .NET (for example a directory with scripts).

## v1.0.4

Added support of incremental and partial incremental builds with new task
parameters `Inputs` and `Outputs`.

## v1.0.3

Errors in task `If` blocks should be fatal even if a task call is protected.

## v1.0.2

Task `If` conditions are either expressions evaluated on task creation or
script blocks evaluated on task invocation. In the latter case a script is
invoked as many times as the task is called until it gets `true` and the task
is invoked.
