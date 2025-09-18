# Get-BuildFile

```text
Gets the found build script path.
```

## Syntax

```text
Get-BuildFile [[-Path] Object] [-Here]
```

## Description

```text
It gets the build script path for the specified or current location, the
first like *.build.ps1 in Sort-Object order.

    If this file is not found then `$env:InvokeBuildGetFile` is called with a
    directory path argument in order to get its custom build script path.

    If the file is still not found then parent directories are searched.
```

## Parameters

```text
-Path
    Specifies the directory path, defaults to the current location.
    
    Required?                    false
    Position?                    0
```

```text
-Here
    Tells not to search in parent directories.
    
    Required?                    false
    Position?                    named
```

## Outputs

```text
String
    The found build script path or null.
```
