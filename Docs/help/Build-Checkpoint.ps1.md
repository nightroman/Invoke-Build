# Build-Checkpoint.ps1

```text
Invokes persistent builds with checkpoints.
```

## Syntax

```text
Build-Checkpoint.ps1 [[-Checkpoint] String] [[-Build] Hashtable] [-Preserve]
```

```text
Build-Checkpoint.ps1 [[-Checkpoint] String] [[-Build] Hashtable] -Auto [-Preserve]
```

```text
Build-Checkpoint.ps1 [[-Checkpoint] String] [[-Build] Hashtable] -Resume [-Preserve]
```

## Description

```text
This command invokes the build and saves build state checkpoints after each
completed task. If the build is interrupted then it may be resumed later
with the saved checkpoint file.

The built-in Export-Clixml and Import-Clixml are used for saving checkpoints.
Keep in mind that not all data types are suitable for this serialization.

CUSTOM EXPORT AND IMPORT

By default, the command saves and restores build tasks, script path, and
all parameters declared by the build script. Tip: consider declaring some
script variables as artificial parameters in order to make them persistent.

If this is not enough for saving and restoring the build state then use
custom export and import blocks. The export block is called on writing
checkpoints, i.e. on each task. The import block is called on resuming
once, before the task to be resumed.

The export block is set by `Set-BuildData Checkpoint.Export`, e.g.

    Set-BuildData Checkpoint.Export {
        $script:var1
        $script:var2
    }

The import block is set by `Set-BuildData Checkpoint.Import`, e.g.

    Set-BuildData Checkpoint.Import {
        param($data)
        $var1, $var2 = $data
    }

The import block is called in the script scope. Thus, $var1 and $var2 are
script variables right away. We may but do not have to use the prefix.

The parameter $data is the output of Checkpoint.Export exported to clixml
and then imported from clixml.

OMITTED OR SCRIPT CHECKPOINT

Omitted or script Checkpoint and no other parameters is the special
case. The engine builds all tasks of the default or specified script
with checkpoints.

The checkpoint path is the script path with added ".clixml". The persistent
build starts if the checkpoint does not exist, otherwise resumes with the
existing checkpoint.
```

## Parameters

```text
-Checkpoint
    Specifies the checkpoint file (clixml). The checkpoint file is removed
    after successful builds unless the switch Preserve is specified.
    
    See DESCRIPTION / OMITTED OR SCRIPT CHECKPOINT for the special case.
    
    Required?                    false
    Position?                    0
```

```text
-Build
    Specifies the build and script parameters. WhatIf is not supported.
    
    When the build resumes by Resume or Auto then fields Task, File, and
    script parameters are ignored and restored from the checkpoint file.
    But fields Result, Safe, Summary are used as usual build parameters.
    
    Required?                    false
    Position?                    1
```

```text
-Auto
    Tells to start a new build if the checkpoint file is not found or
    resume the build from the found checkpoint file.
    
    Required?                    true
    Position?                    named
```

```text
-Preserve
    Tells to preserve the checkpoint file on successful builds.
    
    Required?                    false
    Position?                    named
```

```text
-Resume
    Tells to resume the build from the existing checkpoint file.
    
    Required?                    true
    Position?                    named
```

## Outputs

```text
Text
    Output of the invoked build.
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Invoke a persistent sequence of steps defined as tasks.
Build-Checkpoint temp.clixml @{Task = '*'; File = 'Steps.build.ps1'}

# Given the above failed, resume at the failed step.
Build-Checkpoint temp.clixml -Resume
```

## Links

```text
Invoke-Build
```
