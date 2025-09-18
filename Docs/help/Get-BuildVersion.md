# Get-BuildVersion

```text
Gets version string from file.
```

## Syntax

```text
Get-BuildVersion [-Path] String [-Regex] Object
```

## Description

```text
It finds the first file line matching Regex and returns its first capturing
group string.
```

## Parameters

```text
-Path
    The file with version strings, like change log, release notes, etc.
    
    Required?                    true
    Position?                    0
```

```text
-Regex
    [string] or [regex] defining version as its first capturing group.
    
    Required?                    true
    Position?                    1
```

## Outputs

```text
String
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Get version from file
Get-BuildVersion Release-Notes.md '##\s+v(\d+\.\d+\.\d+)'
```
