# Get-BuildSynopsis

```text
Gets the task synopsis.
```

## Syntax

```text
Get-BuildSynopsis [-Task] Object [[-Hash] Object]
```

## Description

```text
Gets the specified task synopsis if it is available.

Task synopses are defined in preceding comments as

    # Synopsis: ...

or

    <#
    .Synopsis
    ...
    #>

This function may be used in Set-BuildHeader for printing task synopses.
```

## Parameters

```text
-Task
    The task object. During the build, the current task is available as the
    automatic variable $Task.
    
    Required?                    true
    Position?                    0
```

```text
-Hash
    The cache used by external tools. Scripts may omit this parameter.
    
    Required?                    false
    Position?                    1
```

## Outputs

```text
String
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Headers: print task paths as usual and synopses in addition
Set-BuildHeader {
    param($Path)
    print Cyan "Task $Path : $(Get-BuildSynopsis $Task)"
}

# Synopsis: This task prints its own synopsis.
task Task1 {
    'My synopsis : ' + (Get-BuildSynopsis $Task)
}
```

## Links

```text
Set-BuildFooter
Set-BuildHeader
```
