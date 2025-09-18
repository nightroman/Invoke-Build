# Set-BuildFooter

```text
Tells how to write task footers.
```

## Syntax

```text
Set-BuildFooter [[-Script] ScriptBlock]
```

## Description

```text
This build block is used in order to change the default task footer format.
Use the automatic variable $Task in order to get the current task data.
Use Write-Build (print) in order to write with colors.
```

## Parameters

```text
-Script
    The script like {param($Path) ...} which is used in order to write task
    footers. The parameter Path includes the parent and current task names.
    
    In order to omit task footers, set an empty block:
    
        Set-BuildFooter {}
    
    Required?                    false
    Position?                    0
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Use the usual footer format but change the color
Set-BuildFooter {
    param($Path)
    print DarkGray "Done $Path $($Task.Elapsed)"
}

# Synopsis: Data for footers in addition to $Path and $Task.Elapsed
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
Set-BuildHeader
Write-Build (print)
```
