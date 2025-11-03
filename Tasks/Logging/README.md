# Build logging

## Tips

✓ Use `*>&1` to include all streams.

```powershell
Invoke-Build ... *>&1 | Set-Content $myLog
```

✓ Output objects using `Out-String` to avoid unexpected formatting in logs.

```powershell
$myObject | Out-String
$myObject | Format-List | Out-String
```

## Set-Content

`Set-Content` looks good for low ceremony logging:

```powershell
Invoke-Build ... *>&1 | Set-Content $myLog
```

It writes strings literally, not wrapped or truncated.

The default encoding is UTF-8 (Core) or ASCII (Desktop), will do for ASCII output in all versions.

## Out-File

`Out-File` may be used for logging:

```powershell
Invoke-Build ... *>&1 | Out-File $myLog -Width $myWidth -Encoding UTF8
```

It formats data per the host window width. Too small may cause unwanted wrapping or truncation.

Default encoding depends on versions: `utf8NoBOM` (v6.0+), `Unicode` (...v5.1).

## Tee-Object

Build output is not shown in the console on using the above methods.
If it is needed then `Tee-Object` may help:

```powershell
Invoke-Build ... *>&1 | Tee-Object $myLog
```

It works well in PowerShell Core with no obvious width issues, using UTF-8 by default.

In Windows Desktop the output width (Host) and encoding (Unicode) are not configurable.

## Transcript

`Start-Transcript` in `Enter-Build` and `Stop-Transcript` in `Exit-Build`
provide yet another way of logging.

Note that the build script itself controls such logging.
This is different from other methods, with some advantages.

```powershell
Enter-Build {
    Start-Transcript $myLog
}

Exit-Build {
    Stop-Transcript
}
```

Transcribing is especially sensitive to objects written without `Out-String`.
Records may have unexpected order or may be discarded, sometimes with next
records.

Output of native commands is not included to transcripts.
This trick includes native output: `<native-command> | Out-Default`.

## See also

- [Log output · Issue 99](https://github.com/nightroman/Invoke-Build/issues/99)
- [Limitations of PowerShell transcripts](https://learn.microsoft.com/en-us/powershell/scripting/learn/deep-dives/output-missing-from-transcript)
- [Workaround for Start-Transcript on native processes](https://devblogs.microsoft.com/powershell/workaround-for-start-transcript-on-native-processes/)
