# Use-BuildEnv

```text
Invokes script with temporary changed environment variables.
```

## Syntax

```text
Use-BuildEnv [-Env] Hashtable [-Script] ScriptBlock
```

## Description

```text
This command sets the specified environment variables and invokes the
script. Then it restores the original values of specified variables.
```

## Parameters

```text
-Env
    The hashtable of environment variables used by the script.
    Keys and values correspond to variable names and values.
    
    Required?                    true
    Position?                    0
```

```text
-Script
    The script invoked with the specified variables.
    
    Required?                    true
    Position?                    1
```

## Outputs

```text
Objects
    Output of the specified script.
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Invoke with temporary changed Port and Path
Use-BuildEnv @{
    Port = '9780'
    Path = "$PSScriptRoot\Scripts;$env:Path"
} {
    exec { dotnet test }
}
```

## Links

```text
Invoke-BuildExec
```
