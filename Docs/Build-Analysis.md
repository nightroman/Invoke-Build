# Build Analysis

The Invoke-Build parameter `Result` is used to tell where to store build
results like invoked task objects, error and warning objects, list of all
tasks, and an error that stopped a build.

The command for getting results looks like

```powershell
Invoke-Build ... -Result Result
```

It tells to create the variable `$Result` populated with build data.
See help:

```powershell
Get-Help Invoke-Build -Parameter Result
```

## Errors and warnings analysis

The list `$Result.Errors` contains objects:

- `Error` - original error record
- `File` - current `$BuildFile`
- `Task` - current `$Task` or null for non-task errors

The list `$Result.Warnings` contains objects:

- `Message` - warning message
- `File` - current `$BuildFile`
- `Task` - current `$Task` or null for non-task warnings

Analysis of errors and warnings is especially useful in testing scenarios when
several build scripts `*.test.ps1` are invoked:

```powershell
Invoke-Build ** -Safe -Result Result
```

## Task error analysis

In order to get errors by tasks iterate through `$Result.Tasks` and check their
`Error`. In addition to an error there is useful task information as well:
`Name`, `InvocationInfo.ScriptName`, and `InvocationInfo.ScriptLineNumber`.

```powershell
foreach($t in $Result.Tasks) {
    if ($t.Error) {
        "Task '$($t.Name)' at $($t.InvocationInfo.ScriptName):$($t.InvocationInfo.ScriptLineNumber)"
        $t.Error
    }
}
```

## Show tasks summary

This code snippet shows all tasks summary after the build (even failed).

```powershell
try {
    # Invoke the build and keep results in the variable Result
    Invoke-Build -Result Result
}
finally {
    # Show task summary information after the build
    $Result.Tasks | Format-Table Elapsed, Name, Error -AutoSize
}
```

## Show task durations and script names

This code snippet shows all tasks ordered by the `Elapsed` times and adds task
`ScriptName`s to task names (this is useful if different scripts have same task
names, e.g. typical: `Build`, `Clean`, `Test`, ...).

```powershell
# Invoke the build and keep results in the variable Result
Invoke-Build -Result Result

# Show invoked tasks ordered by Elapsed with ScriptName included
$Result.Tasks |
Sort-Object Elapsed |
Format-Table -AutoSize Elapsed, @{
    Name = 'Task'
    Expression = {$_.Name + ' @ ' + $_.InvocationInfo.ScriptName}
}
```
