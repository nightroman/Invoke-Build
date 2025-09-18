# Write-Build

```text
(print) Writes text using colors if they are supported.
```

## Syntax

```text
Write-Build [-Color] ConsoleColor [-Text] String
```

## Description

```text
This function is used in order to output colored text in a console or other
hosts with colors. Unlike Write-Host it is suitable for redirected output.

Write-Build is designed for tasks and build blocks, not script functions.

With PowerShell 7.2+ and $PSStyle.OutputRendering ANSI, Write-Build uses
ANSI escape sequences.
```

## Parameters

```text
-Color
    [System.ConsoleColor] value or its string representation.
    
    Values : Black, DarkBlue, DarkGreen, DarkCyan, DarkRed, DarkMagenta, DarkYellow, Gray, DarkGray, Blue, Green, Cyan, Red, Magenta, Yellow, White
    
    Required?                    true
    Position?                    0
```

```text
-Text
    Text written using colors if they are supported.
    
    Required?                    true
    Position?                    1
```

## Outputs

```text
String
```
