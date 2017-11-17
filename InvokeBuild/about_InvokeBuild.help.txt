TOPIC
    about_InvokeBuild

SHORT DESCRIPTION
    Build and test automation in PowerShell

LONG DESCRIPTION
    The module provides the following commands:

        Invoke-Build
            The alias of Invoke-Build.ps1
            It invokes build scripts, this is the build engine.

        Build-Checkpoint
            The alias of Build-Checkpoint.ps1
            It invokes persistent builds using the engine.

        Build-Parallel
            The alias of Build-Parallel.ps1
            It invokes parallel builds using the engine.

    Import the installed module:

        Import-Module InvokeBuild

    Or import from the specified location:

        Import-Module <path>\InvokeBuild.psd1

    Get help for the engine:

        help <path>\Invoke-Build.ps1 -full

    Get help for build commands:

        . <path>\Invoke-Build.ps1
        help task -full
        help exec -full
        ...

    The package contains the build engine with a few helpers, all you need
    for running build scripts. There are various related tools, see README.
