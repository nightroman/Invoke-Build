# DEV Internal Functions

## `*BB` creates base build info

```text
function *BB($FS, $PX, $BR)
$FS: build file or script block
$PX: prefix of renamed tasks
$BR: @(extended build roots)

Result
- FS: build file or script block
- PX: prefix of renamed tasks
- BR: @(this build root and $BR)
- DP: dynamic parameters
- EnterBuild ExitBuild EnterTask ExitTask EnterJob ExitJob: blocks
```

## `*DP` makes dynamic parameters

```text
function *DP($FS, $PX)
$FS existing build script full path
$PX prefix
```

Dynamic parameters of `$FS` and recursively for its base scripts defined by `Extends`:

- `${*}.DP`: all dynamic parameters including inherited
- `${*}.BB`: base builds, `Extends` tree walk ordered

```text
$BR array of extended build roots, to be passed in *BB and *DP (recursive)
$b base build data, see *BB
$p script parameters, then parameter
$c common parameters
$r reserved parameters
$a parameter attribute
$s extended script path from Extends
$x prefix from Extends
```

Gets `$FS` (full path) parameters by `Get-Command $FS -ErrorAction 1`.
Ditto with `-Type ExternalScript` but a bit slower, so we omit it.

// [#210](https://github.com/nightroman/Invoke-Build/issues/210) suggests using `Cmdlet.CommonParameters()`, reported for PS 7.4 daily.
IB now uses PS 7.3.3, it has this, so we can:

```powershell
if ($PSVersionTable.PSVersion -ge ([version]'7.3.3')) {
    $c = @([System.Management.Automation.Cmdlet]::CommonParameters)
}
```

Yet for now we continue using hardcoded values with the new `ProgressAction` added.

**Issues /152 /217, see /Tests/Issues**
We now shift script positional parameters positions (+2, avoiding conflicts with `Task` and `File`).
In PS v2 this does not change parameter positions (and the problem does not exists perhaps).
In later PS parameter positions keep changing +2, looks like PS caches attributes.
But this works because this shift still preserves parameter relative positions.

## `*SL` sets the current location

```text
function *SL($P=$BuildRoot)
$P - new location, literal path
```

It sets the current location to specified literal path.

This command is frequently called with the omitted argument in order to set the location to the build root.
This is done before running user code and resolving user input paths.

## `*Path` converts a path to full

```text
function *Path($P)
$P - full or relative path
```

It converts the specified path to full depending on the current PowerShell location.
Without arguments it gets the current location.

## `*Die` and `*Fin` throw terminating errors

```text
function *Die($M, $C=0)
$M - error message, [object] converted to [string] as "$M"
$C - error category, [object] converted to [System.Management.Automation.ErrorCategory]
    The following categories are used:
        0  NotSpecified
        5  InvalidArgument
        6  InvalidData
        7  InvalidOperation
        8  InvalidResult
        13 ObjectNotFound
```

`*Die` is used in public functions designed for calls from scripts.
Unlike `throw`, it throws an error which points to the caller.
It also sets some error category.

Important: `*Die` has no cmdlet binding but its callers, i.e. engine functions, must have.

`*Fin` (end, fail internally) is used for the internal failures.
For example, error in `*IO` which is called from `*Task`, not from a script directly.

Important: `*Fin` uses cmdlet binding. Callers have no such restrictions.

**Avoid raw throw**

It looks like `throw` includes the error message in `CategoryInfo` and `FullyQualifiedErrorId`.
In category `CategoryInfo` it may be truncated. In v5 this may be done with ellipses in the middle.
Long and especially multi-line messages result in ugly formatting.

NB:
In the main try-block, use `*Fin` because `*Die` does not trigger the main `catch`, see
[PowerShellTraps/ThrowTerminatingError](https://github.com/nightroman/PowerShellTraps/tree/main/Basic/ThrowTerminatingError/Catch-is-not-called).

## `*Run` runs a command with some extras

```text
function *Run($_)
$_ - command to run
$args - remaining arguments are command arguments
```

It invokes commands with the current location set to the build root.
Commands are normally some user code called on various build blocks.
If `$_` is null the command is ignored.

The parameter `$_` is the only extra variable exposed to user code.
As documented, we do not hide `$_`.

## `*At` gets invocation info position message

```text
function *At($I)
$I - anything with the property InvocationInfo
```

For an object with the property `InvocationInfo` (a task or an error record),
the function returns its amended position message like

```text
At <file>:<line> char <char>
+ ...
```

**Why `Trim()`**

In PS v2 `InvocationInfo.PositionMessage` has the unwanted leading `\n` and the
line separator `\n` instead of `\r\n`. This is fixed in v3. But for v2 we keep
`Trim()` in order to remove the leading `\n`.

## `*Msg` message with source location

```text
function *Msg($M, $I)
$M - error message
$I - anything with the property InvocationInfo
```

It joins an error message and its invocation info position message.

We used here-string to avoid x-plat dependent line ends.
Now we just use `\n` because:
(1) The here-string approach is not reliable.
(2) These strings end up in `Write-Build` which splits into lines anyway.

## `*Check` checks jobs for missing references and cycles

```text
function *Check($J, $T, $P=@())
$J - jobs to check
$T - parent task, omitted for root jobs
$P - parent tasks for cycle checks, omitted for root jobs
```

Plot

```text
for each string job $_
    try to find the task by name $_
    if it is missing
        *Die "Missing task", mind messages depending on $T
    if parent array contains the task
        *Die "Cyclic reference"
    call *Check with the task jobs, the task, parents with this task added
```

## `*Err` adds an error to the result

```text
function *Err($T)
$T - failed task
$_ - current error in the parent catch block
```

It adds the current error `$_` info to `Result.Errors`.

v4.1.0 It also prints the error info, #106.
It is called as soon as an error happens (simple and robust in all scenarios).
We used to delay some errors in order to avoid kind of "duplicated information" (complex and not good with some hosts and redirection).

It is mostly called from `*Task` (condition, IO, action).
And it is called once in the main catch if no errors exist.
It means tasks are not failed so it is a preprocessing error.

## `*My` tells if the current error is internal

```text
function *My
$_ error in the parent scope
```

It returns true if the current error `$_` is thrown by the engine itself and
false if the error is external, i.e. thrown by user code.

When called from `*Task`:

```text
True: log an error message with no source, inner source is useless
False: log a message and the useful external source
```

When called from the main `catch` block:

```text
True: throw a new error, source will point to the caller
False: re-throw preserving the external source
```

## `*Job` gets jobs data

```text
function *Job($J)
$J - job object
```

It validates a job object from `-Jobs`, `-After`, `-Before` and returns the
resolved job (task reference or action script) and the optional job data.

Simple jobs are returned as they are.

References `?<TaskName>` are returned as `@("<TaskName>", 1)`.

The command throws "Invalid job" if `$J` is invalid.
Valid jobs:

- `[string] "TaskName"` - normal task reference
- `[string] "?TaskName"` - safe task reference
- `[scriptblock]` - action

**NB**
If `$J` is known as string, use `$J.TrimStart('?')` instead of `*Job`.

## `*Unsafe` tells if a task is unsafe

```text
# $N - task name
# $J - jobs to be checked
function *Unsafe($N, $J) {

    # if jobs contain task true name (no '?') then the task is referenced unsafe, return 1
    if ($N -in $J) {return 1}

    # walk task trees where roots are the jobs
    foreach($_ in $J) {if ($_ -is [string]) {

        # unwrap (e.g. ?SomeName), $_ is task name
        $_ = $_.TrimStart('?')

        #! Tempting to call *Job, get $safe flag, and `continue` if it is true. DO NOT.
        #! Yes, the build is not going to stop but parents of a failed task with unsafe
        #! references still should fail. So step into and walk the safe branch anyway.
        #! (this is covered by tests, fact 17-11-24)

        # $_ -ne $N -- skip the input, i.e. already failed task
        # $t = ${*}.All[$_] -- get the task object by name, skip null (oddly to flow)
        # $t.If -- skip the task with the false condition, it is not going to run
        # *Unsafe $N $t.Jobs -- test the input name with jobs of the task

        if ($_ -ne $N -and ($t = ${*}.All[$_]) -and $t.If -and (*Unsafe $N $t.Jobs)) {
            return 1
        }
    }
}
```

It checks jobs `$J` with the task `$N` and returns:

```text
1: an unsafe reference is found (build should stop)
nothing: all references are safe (build may continue)
```

The first time it is called with root tasks `$BuildTask` as `$J`:

```powershell
if (*Unsafe ${*j} $BuildTask) {throw}
```

The code is probably not optimal for builds with failing tasks.
But it is compact and this is better for scenarios without failures.

## `*Amend` amends task jobs on preprocessing

```text
function *Amend($X, $J, $B)
$X -- an extra task to be added to tasks specified by $J
$J | $X.Before | $X.After tasks
$B | 1 -- Before | 0 -- After
```

It is called on preprocessing for tasks with parameters `Before` and `After`.

NB: v5.0.0 `$J` is `[string[]]` (from `-After` and `-Before`), so `*Job` cannot fail.

## `*Help` gets task help object

```text
filter *Help($H)
$_ - input task object
$H - cache used by *Synopsis, a caller just passes @{}
```

For an input task it gets a task help object with the properties
`Name`, `Jobs`, and `Synopsis`. It is called in the special case:

```text
Invoke-Build ?
```

`Jobs` is an array, not text (v2.9.7)

- Pros
    - With many jobs the column `Synopsis` is not dropped (try "?" with *Tests/.build.ps1*).
    - Jobs are easier to process or show differently by external tools.
- Cons
    - Only a few jobs are shown by default (`$FormatEnumerationLimit = 4`).
      On the other hand, with many jobs text would be truncated as well.

## `*Root` collects root tasks

```text
function *Root
uses:
- ${*}: build state
- $BuildFile: build script
```

It is used on `Invoke-Build *` in order to filter out tasks with parents and
return the root task names, to be invoked later. It also calls `*Check`.

v5.14.12 The dot-task and tasks from other scripts are not included.

## `*IO` processes task inputs and outputs

```text
function *IO
```

It evaluates inputs and outputs of the current incremental and partial
incremental task and returns a reason to skip, if all is up-to-date.

It is always called from `*Task`, so that it does not have any parameters,
it just uses `$Task`, the parent variable of the current task.

The function returns an array of two values:

```text
[0] result code: 2: output is up-to-date; $null: output is out-of-date
[1] information message
```

In the out-of-date case, the function stores processed input and outputs
as `$Task.Inputs` and `$Task.Outputs`. They are used in `*Task` later.

Plot, mind `*SL` before `*Path` and calling user code:

```text
${*i} = $Task.Inputs ~ invoke if a scriptblock. NB for PS v2 use @(& ..)
*SL and collect ${*p} = full input paths and ${*i} = input converted to FileInfo
if nothing then return (2, 'Skipping empty input.')

NB: *p is array, *i is array or not

if ($Task.Partial) {
    *SL is not needed, it is done above and no user code is invoked after
    ${*o} = $Task.Outputs either invoked (with *SL after this) or cast to array
    if *o and *p counts are different -> 'Different input and output'
    No user code after this, we can use simple variables.
}
else {
    *SL is not needed, it is done above and no user code is invoked after
    invoke output (if a scriptblock), set it back to $Task.Outputs, *SL
    set $Task.Inputs to *p (full input paths)
}
```

NB:
Replaced `Get-Item -LiteralPath .. -Force -ErrorAction Stop` with `[System.IO.FileInfo](*Path ..)`.
The old does not work in paths with `[ ]`.

NB:
At some point replaced `Test-Path -LiteralPath` with `*Path` as well due to paths with `[ ]`.
Later on replaced with times compared with 1601-01-01, see below.

NB: checks for `Exists` [#69](https://github.com/nightroman/Invoke-Build/issues/69)

    At some point redundant checks for `Exists` on output files were removed.
    It is documented that time of a missing file is 1601-01-01.
    v3.3.9 restores checks because Mono is different.

## `*Task` processes a task

```text
function *Task
$args[0] - task name
$args[1] - parent task path or null for a root task
```

This function is the engine's heart, it invokes tasks.

Obtain the task object by name from the build list. Do not check for null, it
should exist. Create this task path from the parent path, it is for the log.

If the task is done then log and return. Before 2.14.4 we used to check for
errors before this and print a different message. It's unlikely very useful.

Evaluate `If`.
If it is false then return.
If it fails then catch and store the error + decorate the task as invoked, then re-throw.

Q: To fail or not if it is a safe call?
We think failures in `If` should be fatal.

Process task jobs in a `try` block.

**CASE:** Job is a task reference

Call the referenced task and go to the next job.

**CASE:** Job is a script block

Input of incremental tasks can be empty, so check for null.
Use case: a task works for some files but it is possible that they do not exist.

```text
# *i[0] is a flag which tells how to deal with *IO
${private:*i} = , [int]($null -ne $Task.Inputs)

    # initial values:
    0: not incremental task
    1: incremental, *IO was not called, call it and print the result info *i[1]

    # new values after called *IO
    2: incremental, *IO was called, skip incremental job
    $null: incremental, *IO was called, do incremental job
```

**Variables `$Task` and `$Job`**

`*Task` creates the variable `$Task`. It is exposed to blocks and actions, it
is used by `*Task` and other engine functions. Some blocks are dot-sourced in
`*Task`. Thus, user code may change `$Task` and break normal processing. That
is why `$Task` is made constant.

Similarly, the read only variable `$Job` is created for each task action.
It is used by the engine itself and may be used by user scripts (#185).

## `*Echo`

> It may not handle all text anomalies or weird formatting as one may expect.
> But it works very well with typical cases and reasonable anomalies.

The first line (code after `{`, if any) is preserved, so its indent is irrelevant.
Cases:

```text
exec { first line }

exec { first line
    ...
}
```

Thus, the common indent is inferred from the next not empty line.

## `*What`

It is called on `$WhatIf` before exiting.
It simply calls `Show-TaskHelp`.

The reason of having this shim instead of just calling `Show-TaskHelp` is
the ability to override with the alias of a user function called from IB.
The function may get some private IB data.

`Show-BuildTree.ps1` used to duplicate some IB code and logic and could be
broken on IB changes. Now it uses `Invoke-Build -WhatIf` with custom `*What`
returning processed and validated tasks data.

Added in v5.14.12.

## `*Write`

This function is documented together with the public `Write-Build`.
