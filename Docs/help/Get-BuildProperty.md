# Get-BuildProperty

```text
(property) Gets the session or environment variable or the default.
```

## Syntax

```text
Get-BuildProperty [-Name] String [[-Value] Object] [-Boolean]
```

## Description

```text
Scripts use its alias 'property'. The command returns:

    - session variable value if it is not $null or ''
    - environment variable if it is not $null or ''
    - default value if it is not $null
    - error
```

## Parameters

```text
-Name
    Specifies the session or environment variable name.
    
    Required?                    true
    Position?                    0
```

```text
-Value
    Specifies the default value. If it is omitted or null then the variable
    must exist with a not empty value. Otherwise an error is thrown.
    
    Required?                    false
    Position?                    1
```

```text
-Boolean
    Treats values like 1 and 0 as $true and $false, including strings with
    extra spaces. Others are converted by [System.Convert]::ToBoolean().
    
    Required?                    false
    Position?                    named
```

## Outputs

```text
Object
    Requested property value.
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Inherit an existing value or throw an error

$OutputPath = property OutputPath
```

```text
-------------------------- EXAMPLE 2 --------------------------
# Get an existing value or use the default

$WarningLevel = property WarningLevel 4
```

## Links

```text
Test-BuildAsset
```
