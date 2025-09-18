# Partial Incremental Tasks

Partial incremental tasks are used in order to improve build performance in
scenarios with one-to-one correspondence between input and output files. The
build engine checks for output files existence and compares their timestamps
with input timestamps. Finally, only input files with missing or out-of-date
outputs are passed in task scripts.

If all outputs are up-to-date then task scripts are not invoked. Note that if
there are referenced tasks then they are invoked in any case.

Here is a partial incremental task template:

```powershell
task Name -Partial -Inputs ... -Outputs ... [-Jobs] {process{ ... }}
```

or using the alternative task syntax:

```powershell
task Name @{
    Partial = $true
    Inputs = ...
    Outputs = ...
    Jobs = {process{ ... }}
}
```

It uses the switch `Partial`, defines the inputs and outputs expressions and
the script, normally with the `process` block in it.

## The inputs

It is a list of input file items or paths or a script block which gets them.
For example, for all markdown files in the build directory it can be:

```powershell
task ... -Inputs (Get-Item *.md, *.markdown)
```

Or with invocation performed when the task is invoked, e.g. if some of markdown
files may be updated during the build (note `{...}` instead of `(...)`):

```powershell
task ... -Inputs {Get-Item *.md, *.markdown}
```

A fixed list of known absolute or relative file paths will do as well:

```powershell
task ... -Inputs README.md, Release-Notes.md
```

The inputs are finally resolved by the engine into the full paths piped to the
outputs if it is a script block (all of them) and to the task script (some of
them). All input files must exist, otherwise the task fails.

## The outputs

It is a list of output file paths or a script block which gets them. There must
be one-to-one correspondence between input and output files taking their order
into account.

If the argument is a script block then it is invoked with the inputs piped to
it. Its goal is to transform each input path into its output pair. For example,
on converting markdown files to HTML files it might be:

```powershell
task ... -Outputs {process{[System.IO.Path]::ChangeExtension($_, 'html')}}
```

Note use of the `process` block. It is called for every input path represented
by the automatic variable `$_` in it. The script processes the current `$_` and
outputs the corresponding output path.

A list of known file names will do as well:

```powershell
task ... -Outputs README.html, Release-Notes.html
```

## The script

The script is invoked with filtered input paths piped to it. Only input paths
with missing or out-of-date output are piped.

Though it is not mandatory, it is typical for partial incremental task scripts
to have the `process` block. This block is called for each input path. The
current input and output paths are represented by the automatic variables `$_`
and `$2` respectively. The script processes the input file `$_` and creates or
updates the output file `$2`:

```powershell
{process{
    # process the file $_ and output results to the file $2
}}
```

The script may also have the `begin` and `end` blocks called once before and
after the `process` iterations. They can use the automatic variables `$Inputs`
(array of resolved full input paths) and `$Outputs` (exactly as it was defined
or returned by a script block):

```powershell
{
    begin {
        # load assemblies, import modules, dot-source scripts, etc.
    }
    process {
        # process the file $_ and output results to the file $2
    }
    end {
        # clean-up
    }
}
```

Note: in PowerShell if a script block is just code with no `begin`, `process`,
and `end` blocks then it is treated as the `end` block. A partial incremental
task can be defined in this way but the code has to deal with entire `$Inputs`
and `$Outputs` instead of `$_` and `$2`.

```powershell
{
    # convert all $Inputs files into $Outputs files
}
```

## Full example

```powershell
# Synopsis: Converts *.md and *.markdown files to *.html
task ConvertMarkdown @{
    Partial = $true
    Inputs = {
        Get-Item *.md, *.markdown
    }
    Outputs = {
        process{
            [System.IO.Path]::ChangeExtension($_, 'html')
        }
    }
    Jobs = {
        process{
            exec { pandoc.exe $_ --standalone --quiet --from=gfm "--output=$2" }
        }
    }
}
```

Note that in the above example the task is defined with a hashtable where keys
and values are task parameter names and values in addition to the task name.
This task syntax may be easier to compose and read. It is possible to specify
`-Partial`, `-Inputs `, and `-Outputs` as usual task parameters, this is up to
an author.

## Dynamic incremental tasks

In some scenarios inputs and outputs are not known but discovered by a script.
In this case incremental tasks may be created dynamically for each discovered
set, see [Tasks/Dynamic](https://github.com/nightroman/Invoke-Build/tree/main/Tasks/Dynamic).

## Inputs making Outputs

As far as inputs and outputs must have one-to-one correspondence, it might be
convenient to generate them both simultaneously. The engine evaluates `Inputs`
before `Outputs`, so that `Inputs` may create data for `Outputs` as well and
store them in a script variable. Then the `Outputs` script uses the variable.
See [#143](https://github.com/nightroman/Invoke-Build/issues/143#issuecomment-468882699).
