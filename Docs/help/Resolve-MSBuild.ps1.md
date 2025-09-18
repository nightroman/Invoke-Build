# Resolve-MSBuild.ps1

```text
Finds the specified or latest MSBuild.
```

## Syntax

```text
Resolve-MSBuild.ps1 [[-Version] String] [[-MinimumVersion] Version] [-Latest]
```

## Description

```text
The script finds the path to the specified or latest version of MSBuild.
It is designed for MSBuild 17.0, 16.0, 15.0, 14.0, 12.0, 4.0, 3.5, 2.0.

For MSBuild 15+ the command uses the module VSSetup, see PSGallery.
If VSSetup is not installed then the default locations are used.
VSSetup is required for not default installations.

MSBuild 15+ resolution: the latest major version (or absolute if -Latest),
then Enterprise, Professional, Community, BuildTools, other products.

For MSBuild 2.0-14.0 the information is taken from the registry.
```

## Parameters

```text
-Version <String>
    Specifies the required MSBuild major version. If it is omitted, empty,
    or *, then the command finds and returns the latest installed version.
    The optional suffix x86 tells to use 32-bit MSBuild.
    Versions: 17.0, 16.0, 15.0, 14.0, 12.0, 4.0, 3.5, 2.0.
    
    Required?                    false
    Position?                    1
    Accept pipeline input?       false
    Accept wildcard characters?  false
```

```text
-MinimumVersion <Version>
    Specifies the required minimum MSBuild version. If the resolved version
    is less than the minimum then the commands terminates with an error.
    
    Required?                    false
    Position?                    2
    Accept pipeline input?       false
    Accept wildcard characters?  false
```

```text
-Latest [<SwitchParameter>]
    Tells to select the latest minor version if there are 2+ products with
    the same major version. Note that major versions have higher precedence
    than products regardless of -Latest.
    
    Required?                    false
    Position?                    named
    Default value                False
    Accept pipeline input?       false
    Accept wildcard characters?  false
```

## Outputs

```text
The full path to MSBuild.exe
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
Resolve-MSBuild 17.0x86
Gets the location of 32-bit MSBuild of Visual Studio 2022.
```

```text
-------------------------- EXAMPLE 2 --------------------------
Resolve-MSBuild -MinimumVersion 16.3.1 -Latest
Gets the location of the latest MSBuild, and asserts its version is 16.3.1+.
```

```text
-------------------------- EXAMPLE 3 --------------------------
Resolve-MSBuild x86 -MinimumVersion 15.0 -Latest
Gets the location of the latest 32-bit MSBuild, and asserts its version is 15.0+.
```

## Links

```text
https://www.powershellgallery.com/packages/VSSetup
```
