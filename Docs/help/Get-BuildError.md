# Get-BuildError

```text
Gets the specified task error.
```

## Syntax

```text
Get-BuildError [-Task] String
```

## Description

```text
The specified task is usually safe referenced in the build (?name) and a
caller (usually a downstream task) gets its potential error for analysis.
```

## Parameters

```text
-Task
    Name of the task which error is requested.
    
    Required?                    true
    Position?                    0
```

## Outputs

```text
Error
    An error or null if the task has not failed.
```

## Links

```text
Add-BuildTask
```
