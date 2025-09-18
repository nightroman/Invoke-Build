# Test-BuildAsset

```text
(requires) Checks for required build assets.
```

## Syntax

```text
Test-BuildAsset [[-Variable] String[]] [-Environment String[]] [-Path String[]] [-Property String[]]
```

## Description

```text
Scripts use its alias 'requires'. This command tests the specified assets.
It fails if any is missing. It is used in script code (common assets) and
in tasks (individual assets).
```

## Parameters

```text
-Variable
    Specifies the required session variable names and tells to fail if a
    variable is missing or its value is null or empty string.
    
    Required?                    false
    Position?                    0
```

```text
-Environment
    Specifies the required environment variable names.
    
    Required?                    false
    Position?                    named
```

```text
-Path
    Specifies literal paths to be tested by Test-Path. If the specified
    expression uses required assets then test these assets first by a
    separate command.
    
    Required?                    false
    Position?                    named
```

```text
-Property
    Specifies session or environment variable names and tells to fail if a
    variable is missing or its value is null or empty string.
    
    Required?                    false
    Position?                    named
```

## Links

```text
Get-BuildProperty
```
