# Invoke-BuildExec

```text
(exec) Invokes an application and checks $LastExitCode.
```

## Syntax

```text
Invoke-BuildExec [-Command] ScriptBlock [[-ExitCode] Int32[]] [[-ErrorMessage] String] [-Echo] [-StdErr]
```

## Description

```text
Scripts use its alias 'exec'. It invokes the script block which is supposed
to call an executable. Then $LastExitCode is checked. If it does not match
the specified codes (0 by default) an error is thrown.

If you have any issues with standard error output of the invoked app, try
using `exec` with -ErrorAction Continue, SilentlyContinue, or Ignore. This
does not affect failures of `exec`, they still depend on the app exit code.
This works around PowerShell standard errors issues.
```

## Parameters

```text
-Command
    Command that invokes an executable which exit code is checked. It must
    invoke an application directly (.exe) or not (.cmd, .bat), otherwise
    $LastExitCode is not set and may contain the code of another command.
    
    Required?                    true
    Position?                    0
```

```text
-ExitCode
    Valid exit codes (e.g. 0..3 for robocopy).
    
    Required?                    false
    Position?                    1
    Default value                @(0)
```

```text
-ErrorMessage
    Specifies the text included to standard error messages.
    
    Required?                    false
    Position?                    2
```

```text
-Echo
    Tells to write the command and its used variable values.
    WARNING: With echo you may expose sensitive information.
    
    Required?                    false
    Position?                    named
```

```text
-StdErr
    Tells to set $ErrorActionPreference to Continue, capture all output and
    write as strings. Then, if the exit code is failure, add the standard
    error output text to the error message.
    
    Required?                    false
    Position?                    named
```

## Outputs

```text
Objects
    Output of the specified command.
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
# Call robocopy (0..3 are valid exit codes)

exec { robocopy Source Target /mir } (0..3)
```

## Links

```text
Use-BuildAlias
Use-BuildEnv
```
