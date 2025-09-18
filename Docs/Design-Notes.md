# Design Notes

See also:

- [DEV Internal Functions](DEV-Internal-Functions.md) - documentation of internal functions
- [DEV Public Functions](DEV-Public-Functions.md) - design notes on public functions

## General purpose task runner

In spite of the name, Invoke-Build is not necessarily for building something.
It offers programming with tasks and their relations. Scripts with tasks are
often easier to compose and use than traditional scripts with functions, see
[Concepts](Concepts.md).

Invoke-Build is designed to be a general purpose programming tool in the first
place. It is also a build automation tool just because typical build workflows
are easily described and automated with tasks.

## Why is it a script?

Why is the command `Invoke-Build` implemented as a script, i.e. not a function
of a script module or library?

The main reason which overweights all disadvantages is that a script has its
own scope which is referenced using the prefix, e.g. `$script:Variable`. As a
result, tasks may maintain their shared state in a very natural way, as script
scope parameters, variables, functions, aliases, and etc.

The script `Invoke-Build.ps1` may be called directly, i.e. without loading a
module or even having the module installed.

There are minor disadvantages. Suboptimal performance on multiple calls is one
of them. But the cost is really low and comparable with inevitable parsing and
especially running build scripts.

Some internals are exposed to user code. The work around this is use of weird
names so that chances of conflicts are small. Also, internals do not pollute
the calling scope, they are gone when a build completes.

## Jobs instead of Depends and Action

Unlike other tasks runners, Invoke-Build does not have an explicit parameter
for task dependencies. Instead, it uses the parameter `Jobs`, where jobs are
task references and actions in any required number and order. This covers the
classic dependency scenarios and more complex: after-tasks, multiple actions.

See [Task dependency syntax clarity](https://github.com/nightroman/Invoke-Build/issues/26)

## Aliases as DSL commands

Invoke-Build provides most of its its DSL commands for scripts as aliases, not
functions, because aliases have higher precedence on command name resolution.

Imagine, `task` is a function and a PowerShell session already has an alias
`task` of `Do-Something` defined. Then build scripts would not work properly
because `Do-Something` is actually invoked on their `task` statements.

Thus, Invoke-Build exposes the function `Add-BuildTask` (Verb-PrefixNoun, as
recommended in PowerShell) and its short alias `task` as the DSL command for
scripts. In this case, the existing alias `task` is not a problem, it is
hidden by the alias of `Add-BuildTask`.

## Continue on error

Tasks do not have an option like "continue on error". A task does not know
whether or not its failure is fatal for a build. It is a caller of a task
decides, i.e. another task or some `Invoke-Build` command. Start a task
reference with "?" in order to allow its failures.

Example. The task *Help* makes help files. It is referenced by two other tasks:

```powershell
task Help {<# make help files #>}

task Package ..., Help, {<# make a package #>}

task Test ..., ?Help, {<# invoke tests #>}
```

The task *Package* is supposed to fail if *Help* fails. So *Package* references
*Help* normally as `"Help"`.

The task *Test* is not supposed to fail if help files are not created, tests
should be invoked anyway. That is why *Test* uses a safe reference to *Help*
as `"?Help"`.

## Removed parameters

Why do some commands copy their parameters to private variables and remove
parameter variables after that?

This is done in order to hide the engine presence from a user code as much as
possible, as if this code is invoked directly in PowerShell, not by the engine.
Not removed parameters of engine commands would be exposed to scripts with some
adverse effects.

For example the parameter *Result* would hide an existing parent scope variable
*Result* which is supposed to be used in a build script.

Or a user task may use its own local variable *Result*. If by mistake or not it
is used uninitialised then the value of not removed parameter *Result* would be
used unintentionally.

## Weird internal names

Invoke-Build uses internal functions and variables. Even being declared private
some of them are exposed to various code defined in build scripts. In order to
minimize chances of conflicts weird internal names starting with `*` are used.

Invoke-Build tries to minimize the number of variables exposed to user code in
order to reduce noise on tasks debugging. Variables are often reused and their
names become meaningless, so that just some short names are used.

## Source code is difficult

This is true for the engine `Invoke-Build.ps1`. The engine is feature complete,
mostly bugs free, well documented and covered by tests. Its code is designed
for better performance and other runtime values, not browsing.

Users do not have to look at the engine code in order to learn how to use it.
The documentation is provided. Help alone is larger than the source code. And
extra docs pages make the documentation pretty exhaustive.

Contributors may have to understand the code. Design notes are provided to make
this easier, see the page top. If something is not clear, it will be explained.
