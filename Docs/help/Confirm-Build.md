# Confirm-Build

```text
Prompts to confirm an operation.
```

## Syntax

```text
Confirm-Build [[-Query] String] [[-Caption] String]
```

## Description

```text
This function prints the prompt and options: [Y] Yes [N] No [S] Suspend.
Choose Y to continue or N to skip. [S] enters the nested prompt, you may
invoke some commands end then `exit`.

Confirm-Build must not be called during non interactive builds. Scripts
should take care of this. For example, add the switch $Quiet and define
Confirm-Build as "Yes to All":

    if ($Quiet) {function Confirm-Build {$true}}
```

## Parameters

```text
-Query
    The confirmation query. If it is omitted or empty, "Continue with this operation?" is used.
    
    Required?                    false
    Position?                    0
```

```text
-Caption
    The confirmation caption. If it is omitted, the current task or script name is used.
    
    Required?                    false
    Position?                    1
```

## Outputs

```text
Boolean
```
