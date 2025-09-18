# Build-Parallel.ps1

```text
Invokes parallel builds by Invoke-Build.
```

## Syntax

```text
Build-Parallel.ps1 [[-Build] Hashtable[]] [-MaximumBuilds Int32] [-Result Object] [-ShowParameter String[]] [-Timeout Int32] [-FailHard]
```

## Description

```text
This script invokes several build scripts simultaneously by Invoke-Build.
Number of parallel builds is set to the number of processors by default.

NOTE: Avoid using Build-Parallel in scenarios with PowerShell classes.
Known issues: https://github.com/nightroman/Invoke-Build/issues/180

VERBOSE STREAM

Verbose messages are propagated to the caller if Verbose is set to true in
build parameters. They are written all together before the build output.

    Build-Parallel @(
        @{File=...; Task=...; Verbose=$true}
        ...
    )

INFORMATION STREAM

Information messages are propagated to the caller if InformationAction is
set to Continue in build parameters. They are written all together before
the build output.

    Build-Parallel @(
        @{File=...; Task=...; InformationAction='Continue'}
        ...
    )

In addition or instead, information messages are collected in the variable
specified by InformationVariable in build parameters.

    Build-Parallel @(
        @{File=...; Task=...; InformationVariable='info'}
        ...
    )

    # information messages
    $info
```

## Parameters

```text
-Build
    Build parameters defined as hashtables with these keys/data:
    
        Task, File, ... - Invoke-Build.ps1 and script parameters
        Log - Tells to write build output to the specified file
    
    Any number of builds is allowed, including 0 and 1. The maximum number
    of parallel builds is the number of processors by default. It can be
    changed by the parameter MaximumBuilds.
    
    Required?                    false
    Position?                    0
```

```text
-FailHard
    Tells to abort all builds if any build fails.
    
    Required?                    false
    Position?                    named
```

```text
-MaximumBuilds
    Maximum number of builds invoked at the same time.
    
    Required?                    false
    Position?                    named
    Default value                Number of processors.
```

```text
-Result
    Tells to output build results using a variable. It is either a name of
    variable to be created for results or any object with the property
    Value to be assigned ([ref], [hashtable]).
    
    Result properties:
    
        Tasks - tasks (*)
        Errors - errors (*)
        Warnings - warnings (*)
        Started - start time
        Elapsed - build duration
    
    (*) see: help Invoke-Build -Parameter Result
    
    Required?                    false
    Position?                    named
```

```text
-ShowParameter
    Tells to show the specified parameter values in build titles.
    
    Required?                    false
    Position?                    named
```

```text
-Timeout
    Maximum overall build time in milliseconds.
    
    Required?                    false
    Position?                    named
```

## Outputs

```text
Text
    Output of invoked builds and other log messages.
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
PS>
Build-Parallel @(
    @{File='Project1.build.ps1'}
    @{File='Project2.build.ps1'; Task='MakeHelp'}
    @{File='Project2.build.ps1'; Task='Build', 'Test'}
    @{File='Project3.build.ps1'; Log='C:\TEMP\Project3.log'}
    @{File='Project4.build.ps1'; Configuration='Release'}
)

Five parallel builds are invoked with various combinations of parameters.
Note that it is fine to invoke the same build script more than once if
build flows specified by different tasks do not conflict.
```

## Links

```text
Invoke-Build
```
