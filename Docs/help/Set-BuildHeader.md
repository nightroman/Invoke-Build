# Set-BuildHeader

```text
Tells how to write task headers.
```

## Syntax

```text
Set-BuildHeader [[-Script] ScriptBlock]
```

## Description

```text
This build block is used in order to change the default task header format.
Use the automatic variable $Task in order to get the current task data.
Use Write-Build (print) in order to write with colors.
```

## Parameters

```text
-Script
    The script like {param($Path) ...} which is used in order to write task
    headers. The parameter Path includes the parent and current task names.
    
    Required?                    false
    Position?                    0
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Headers: write task paths as usual and synopses in addition
Set-BuildHeader {
    param($Path)
    print Cyan "Task $Path --- $(Get-BuildSynopsis $Task)"
}

# Synopsis: Data for headers in addition to $Path and Get-BuildSynopsis
task Task1 {
    'Task name     : ' + $Task.Name
    'Start time    : ' + $Task.Started
    'Location path : ' + $Task.InvocationInfo.ScriptName
    'Location line : ' + $Task.InvocationInfo.ScriptLineNumber
}
```

## Links

```text
Get-BuildSynopsis
Set-BuildFooter
Write-Build (print)
```
