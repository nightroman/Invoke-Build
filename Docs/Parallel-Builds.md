# Parallel Builds

The script `Build-Parallel.ps1` is used in order to invoke several builds at
the same time. The module `InvokeBuild` provides the alias `Build-Parallel`.

**NOTE**: Avoid using `Build-Parallel` in scenarios with PowerShell classes.
Known issues: [#180](https://github.com/nightroman/Invoke-Build/issues/180).

Builds should be independent and should not conflict. Any number of builds is
allowed, including 0 and 1, normally there are 2+. By default, the number of
parallel builds is the number of processors, changed by `MaximumBuilds`.

Every script is invoked in its own runspace, as if PowerShell is just started.
Build scripts should configure environment for their tasks. Calling scripts
cannot do all this but they can prepare and pass data in child builds using
parameters.

Builds are specified by hashtables where keys and values are the `Invoke-Build`
parameters, own and propagated from build scripts. The extra entry `Log` tells
to write a particular build output to the specified file.

## Example

Five parallel builds are invoked with various combinations of build parameters.
Note that it is fine to reference a build script more than once if build flows
specified by different tasks do not conflict:

```powershell
Build-Parallel @(
    @{File='Project1.build.ps1'}
    @{File='Project2.build.ps1'; Task='MakeHelp'}
    @{File='Project2.build.ps1'; Task='Build', 'Test'}
    @{File='Project3.build.ps1'; Log='C:\TEMP\proj3.log'}
    @{File='Project4.build.ps1'; Configuration='Release'}
)
```

## Build order is unknown

Build logs are shown in the same order as builds are specified in the list. But
the order of start and completion times is not known or guaranteed to be always
the same. That is why builds should be independent.

## Avoid host cmdlets and UI members

Any user interaction and use of host cmdlets and UI members should be removed
from scripts designed for parallel builds.

Alternatively, scripts may be prepared to work in standard and parallel modes
differently. Use a script parameter in order to tell what the current mode is
(e.g. the switch `-NoUI` to be used on calls by `Build-Parallel`).

Or this simple trick may work: check for the host name. If it is `Default Host`
then host cmdlets and members should be avoided, replaced with something, or
redefined. `Write-Host`, for example, can be redefined for doing nothing.

```powershell
# Define empty Write-Host for "Default Host"
if ($Host.Name -eq "Default Host") {
    function Write-Host {}
}
```

There are more things to avoid in parallel builds. This area is complex and
subtle. Some PowerShell core features and commands may not work as expected.
PowerShell classes were already mentioned.
