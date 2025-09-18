# Invoke-Build.ps1

```text
Invokes build script tasks.
```

## Syntax

```text
Invoke-Build.ps1 [[-Task] String[]] [[-File] Object] [-Result Object] [-Safe] [-Summary] [-WhatIf]
```

## Description

```text
The command invokes so called tasks defined in a PowerShell script.
Let's call this process build and a script with tasks build script.

A build script defines parameters, variables, and one or more tasks.
Any code is invoked with the current location set to $BuildRoot,
the script directory. $ErrorActionPreference is set to 'Stop'.

SCRIPT PARAMETERS

Build scripts define parameters as usual using the param() block.
On calling, specify them for Invoke-Build as if they are its own.

Known issue #4. Specify script switches after Task and File.

These parameters are reserved for Invoke-Build:
Task, File, Result, Safe, Summary, WhatIf

COMMANDS AND HELP

Commands available for build scripts:

    task      (Add-BuildTask)
    exec      (Invoke-BuildExec)
    assert    (Assert-Build)
    equals    (Assert-BuildEquals)
    remove    (Remove-BuildItem)
    print     (Write-Build)
    property  (Get-BuildProperty)
    requires  (Test-BuildAsset)
    use       (Use-BuildAlias)

    Confirm-Build
    Get-BuildError
    Get-BuildFile
    Get-BuildSynopsis
    Get-BuildVersion
    Resolve-MSBuild
    Set-BuildFooter
    Set-BuildHeader
    Use-BuildEnv
    Write-Warning [1]

[1] Write-Warning is redefined internally in order to count warnings in
a build script and others called. Warnings in modules are not counted.

To get commands help, dot-source Invoke-Build and then call help:

    PS> . Invoke-Build
    PS> help task -full

SPECIAL ALIASES

    Invoke-Build
    Build-Parallel
    Build-Checkpoint

Aliases are for scripts from the package. Use aliases for calling nested
builds, i.e. omit ".ps1" extensions, to avoid accidentally calling other
scripts with same names in the path.

PUBLIC VARIABLES

    $OriginalLocation - where the build is invoked
    $WhatIf - WhatIf mode, Invoke-Build parameter
    $BuildRoot - build script location, by default
    $BuildFile - build script path
    $BuildTask - initial tasks
    $Task - current task
    $Job - current job

All variables except $BuildRoot are for reading and should not be changed.
$BuildRoot may be changed on loading by top level script code, in order to
alter the default build directory, and should not be changed after loading.

$Task is available for script blocks defined by task parameters If, Inputs,
Outputs, and Jobs and by blocks Enter|Exit-BuildTask, Enter|Exit-BuildJob,
Set-BuildHeader, Set-BuildFooter.

    $Task properties for reading:

    - Name - [string], task name
    - Jobs - [object[]], task jobs
    - Started - [DateTime], task start time

    And in Exit-BuildTask:

    - Error - task error or null
    - Elapsed - [TimeSpan], task duration

    Other properties should not be used by scripts.

$Task also exists in the script scope with the only property Name getting
$BuildFile, the build script path.

BUILD BLOCKS

Scripts may define special build blocks invoked as:

    Enter-Build {} - before the first task
    Exit-Build {} - after the last task

    Enter-BuildTask {} - before each task
    Exit-BuildTask {} - after each task

    Enter-BuildJob {} - before each task script job
    Exit-BuildJob {} - after each task script job

    Set-BuildHeader {param($Path)} - to write task headers
    Set-BuildFooter {param($Path)} - to write task footers

Blocks are not called on WhatIf.
Nested builds do not inherit Enter/Exit blocks.
Nested builds inherit Set-BuildHeader and Set-BuildFooter.
If Enter-X is called then Exit-X is also called, even on failures.

Enter-Build and Exit-Build are invoked in the script scope. Enter-Build is
suitable for initialization and it may output text unlike top level code.

Enter-BuildTask, Exit-BuildTask, Enter-BuildJob, and Exit-BuildJob are
invoked in the same scope, the parent of task script blocks.

PRIVATE STUFF

Function and variable names starting with '*' are reserved for the engine.
```

## Parameters

```text
-Task
    One or more tasks to invoke. If it is omitted, empty, or equal to '.'
    then the task '.' is invoked if it exists, otherwise the first added
    task is invoked.
    
    Names with wildcard characters are reserved for special cases.
    
    SAFE REFERENCES
    
    If a task 'X' is referenced as '?X' then it is allowed to fail without
    breaking the build, i.e. other tasks specified after X will be invoked.
    
    SPECIAL TASKS
    
    ? - Tells to show tasks synopses, jobs, and check for issues.
    Task synopses are defined in preceding comments as
    
        # Synopsis: ...
    
    or
    
        <#
        .Synopsis
        ...
        #>
    
    ?? - Tells to collect and get all tasks as an ordered dictionary.
    It can be used by external tools for analysis, completion, etc.
    
    Tasks ? and ?? set $WhatIf to true. Properly designed build scripts
    should not perform anything significant if $WhatIf is set to true.
    
    * - Tells to invoke all tasks, e.g. tests, step sequences, etc.
    The dot-task and tasks added by other scripts are not included.
    
    ** - Invokes * for all files *.test.ps1 found recursively in the
    current directory or a directory specified by the parameter File.
    
    Required?                    false
    Position?                    0
```

```text
-File
    The build script adding tasks by 'task' (Add-BuildTask).
    
    If File is omitted then Invoke-Build searches for the first like
    *.build.ps1 in the current location in Sort-Object order.
    
    If this file is not found then `$env:InvokeBuildGetFile` is called with
    a directory path argument in order to get its custom build script path.
    
    If the file is still not found then parent directories are searched.
    
    DIRECTORY PATH
    
    File accepts directory paths as well. The build script is resolved as
    described above for the specified directory without searching parents.
    
    INLINE SCRIPT
    
    File also accepts a script block composed as build script. In this
    case $BuildFile is a file defining the script block. $BuildRoot is
    its directory or $OriginalLocation when $BuildFile is null on
    [scriptblock]::Create() used instead of usual {...}.
    
    Script parameters, parallel, and persistent builds are not supported.
    
    Required?                    false
    Position?                    1
```

```text
-Result
    Tells to make the build result. Normally it is the name of a variable
    created in the calling scope. Or it is a hashtable which entry Value
    contains the result.
    
    Result properties:
    
        All - all available tasks
        Error - a terminating build error
        Tasks - invoked tasks including nested
        Errors - error objects including nested
        Warnings - warning objects including nested
        Redefined - list of original redefined tasks
    
    Tasks is a list of objects:
    
        Name - task name
        Jobs - task jobs
        Error - task error
        Started - start time
        Elapsed - task duration
        InvocationInfo - task location (.ScriptName, .ScriptLineNumber)
    
    Errors is a list of objects:
    
        Error - original error
        File - current $BuildFile
        Task - current $Task or null for other errors
    
    Warnings is a list of objects:
    
        Message - warning message
        File - script emitting the warning
        Task - current $Task or null for other warnings
    
    Do not change these data and do not use not documented members.
    
    Required?                    false
    Position?                    named
```

```text
-Safe
    Tells to catch a build failure, store an error as the property Error of
    Result and return quietly. A caller should use Result and check Error.
    
    Exceptions are still thrown if the build cannot start, for example:
    build script is missing, invalid, has no tasks.
    
    When Safe is used together with the special task ** (invoke *.test.ps1)
    then task failures stop current test scripts, not the whole testing.
    
    Required?                    false
    Position?                    named
```

```text
-Summary
    Tells to show summary information after the build. It includes task
    durations, names, locations, and error messages.
    
    Required?                    false
    Position?                    named
```

```text
-WhatIf
    Tells to show tasks and jobs to be invoked and some analysis of used
    parameters and environment variables. See Show-TaskHelp.ps1 for more.
    
    If a script does anything but adding tasks then it should check for
    $WhatIf and skip actions on true. Consider using Enter-Build instead.
    
    Required?                    false
    Position?                    named
```

## Outputs

```text
Text
    Build log which includes task records and engine messages, warnings,
    errors, and output from build script tasks and special blocks.

    The script top level code should not output anything. Unexpected script
    outputs now emit warnings but in the future they may change to errors.
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
## How to call Invoke-Build in order to deal with build failures.
## Use one of the below techniques or you may miss some failures.

## (1/2) If you do not want to catch errors and just want the calling
## script to stop on build failures then

$ErrorActionPreference = 'Stop'
Invoke-Build ...

## (2/2) If you want to catch build errors and proceed further depending
## on them then use try/catch, $ErrorActionPreference does not matter:

try {
    Invoke-Build ...
    # Build completed
}
catch {
    # Build FAILED, $_ is the error
}
```

```text
-------------------------- EXAMPLE 2 --------------------------
# Invoke tasks Build and Test from the default script with parameters.
# The script defines parameters Output and WarningLevel by param().

Invoke-Build Build, Test -Output log.txt -WarningLevel 4
```

```text
-------------------------- EXAMPLE 3 --------------------------
# Show tasks in the default script and the specified script

Invoke-Build ?
Invoke-Build ? Project.build.ps1

# Custom formatting is possible, too

Invoke-Build ? | Format-Table -AutoSize
Invoke-Build ? | Format-List Name, Synopsis
```

```text
-------------------------- EXAMPLE 4 --------------------------
# Get task names without invoking for listing, TabExpansion, etc.

$all = Invoke-Build ??
$all.Keys
```

```text
-------------------------- EXAMPLE 5 --------------------------
# Invoke all in Test1.test.ps1 and all in Tests\...\*.test.ps1

Invoke-Build * Test1.test.ps1
Invoke-Build ** Tests
```

```text
-------------------------- EXAMPLE 6 --------------------------
# How to use build results, e.g. for summary

try {
    # Invoke build and get the variable Result
    Invoke-Build -Result Result
}
finally {
    # Show build error
    "Build error: $(if ($Result.Error) {$Result.Error} else {'None'})"

    # Show task summary
    $Result.Tasks | Format-Table Elapsed, Name, Error -AutoSize
}
```

## Links

```text
https://github.com/nightroman/Invoke-Build/blob/main/Docs/help/Invoke-Build.ps1.md
Build-Checkpoint
Build-Parallel
For other commands, at first invoke:
PS> . Invoke-Build
task      (Add-BuildTask)
exec      (Invoke-BuildExec)
assert    (Assert-Build)
equals    (Assert-BuildEquals)
remove    (Remove-BuildItem)
print     (Write-Build
property  (Get-BuildProperty)
requires  (Test-BuildAsset)
use       (Use-BuildAlias)
Confirm-Build
Get-BuildError
Get-BuildSynopsis
Resolve-MSBuild
Set-BuildFooter
Set-BuildHeader
```
