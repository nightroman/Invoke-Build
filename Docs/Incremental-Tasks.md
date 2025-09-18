# Incremental Tasks

Incremental tasks are used in order to improve build performance by skipping
jobs which output files are created or updated after the last modification of
the corresponding input files.

Tasks with one-to-one correspondence between input and output files are called "partial incremental".
They use the build pattern described in [Partial Incremental Tasks](Partial-Incremental-Tasks.md).
A typical example is conversion of files from one format into another.

Other incremental tasks do not have one-to-one input-output correspondence but
they still have input files to be converted into one or more output files. For
example input is a set of *.cs* files and the output is an assembly file
(*.dll* or *.exe*) built from input.

Here is an incremental task template:

```powershell
task Name -Inputs ... -Outputs ... [-Jobs] { ... }
```

or using the alternative task syntax:

```powershell
task Name @{
    Inputs = ...
    Outputs = ...
    Jobs = { ... }
}
```

It normally defines at least these three pieces: the inputs and outputs
expressions and the script that produces the output files from the input.

## The inputs

It is a list of input file items or paths or a script block which gets them.
For example, for all *.cs* files in the build directory it can be:

```powershell
task ... -Inputs (Get-Item *.cs) -Outputs ...
```

or almost the same with a script block:

```powershell
task ... -Inputs {Get-Item *.cs} -Outputs ...
```

The main difference between the first and the second is that the first input is
evaluated on task creation (always) and the second only on task invocation. If
a task is not always invoked then the second form may improve performance. But
the first form catches potential issues earlier, before any task is invoked.

A fixed list of known absolute or relative file paths will do as well:

```powershell
task ... -Inputs Class.cs, AssemblyInfo.cs -Outputs ...
```

The inputs are finally resolved by the engine into the full paths represented
by the automatic variable `$Inputs`. All input files must exist, otherwise the
task fails.

## The outputs

It is a list of output file paths or a script block which gets them. A single
file path is allowed, too. Empty output is not allowed.

If any of output items is missing then the task scripts are invoked. Otherwise
the engine compares timestamps. If the minimum of outputs is less than the
maximum of inputs then the task scripts are invoked.

```powershell
task ... -Inputs ... -Outputs Library.dll
```

## The script

The script builds the output files from the input files. There are two helper
automatic variables defined: the `$Inputs` (array of resolved full input paths)
and the `$Outputs` (exactly as it was defined or returned by a script block).
Scripts can but do not have to use them, like in this example:

```powershell
{
    exec { csc /optimize /target:library /out:Library.dll *.cs }
}
```

## Full example

Here is the build script with an incremental task combined from the pieces above:

```powershell
# Use the .NET 4.0 compiler
use 4.0 csc

# Build the Library.dll if it is missing or out-of-date
task Build -Inputs { Get-Item *.cs } -Outputs Library.dll {
    exec { csc /optimize /target:library /out:Library.dll *.cs }
}
```

## Composing tasks

Inputs and outputs are often not trivial script blocks and normal task syntax
may be hard to compose and read. If this is the case use a hashtable to define
task parameters in addition to the task name:

```powershell
# Synopsis: Complex task with parameters as a hashtable.
task TestAndAnalyse @{
    If = !$SkipAnalyse
    Inputs = {
        Get-ChildItem . -Recurse -Include *.ps1, *.psm1
    }
    Outputs = {
        'Analyser.log'
    }
    Jobs = 'Test', {
        Invoke-ScriptAnalyzer . > Analyser.log
    }
}

# Synopsis: Simple task with usual parameters.
task Test -If (!$SkipTest) {
    Invoke-Pester
}
```

## Dynamic incremental tasks

In some scenarios inputs and outputs are not known but discovered by a script.
In this case incremental tasks may be created dynamically for each discovered
set, see [Tasks/Dynamic](https://github.com/nightroman/Invoke-Build/tree/main/Tasks/Dynamic).
