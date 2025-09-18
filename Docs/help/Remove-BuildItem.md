# Remove-BuildItem

```text
(remove) Removes specified items.
```

## Syntax

```text
Remove-BuildItem [-Path] String[]
```

## Description

```text
Scripts use its alias 'remove'. This command removes existing items,
ignores missing items, and fails if it cannot remove existing items.

Use the switch Verbose in order to output messages about removing
existing and skipping missing items or patterns specified by Path.
```

## Parameters

```text
-Path
    Specifies the items to be removed. Wildcards are allowed.
    The parameter is mostly the same as Path of Remove-Item.
    For sanity, paths with only ., *, \, / are not allowed.
    
    Required?                    true
    Position?                    0
    Accept wildcard characters?  true
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Remove some temporary items

remove bin, obj, *.test.log
```
