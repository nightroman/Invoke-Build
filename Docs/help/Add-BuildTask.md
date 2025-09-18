# Add-BuildTask

```text
(task) Defines and adds a task.
```

## Syntax

```text
Add-BuildTask [-Name] String [[-Jobs] Object] [-After String[]] [-Before String[]] [-Data Object] [-Done Object] [-If Object] [-Inputs Object] [-Outputs Object] [-Source Object] [-Partial]
```

## Description

```text
Scripts use its alias 'task'. It is normally used in the build script scope
but it can be called from another script or function. Build scripts should
have at least one task.

This command is all that build scripts really need. Tasks are main build
blocks. Other build commands are helpers, scripts do not have to use them.

In addition to task parameters, you may use task help comments, synopses,
preceding task definitions:

    # Synopsis: ...
    task ...

Synopses are used in task help information returned by the command

    Invoke-Build ?

To get a task synopsis during a build, use Get-BuildSynopsis.
```

## Parameters

```text
-Name
    The task name. Wildcard characters are deprecated and "?" must not be
    the first character. Duplicated names are allowed, each added task
    overrides previously added with the same name.
    
    Required?                    true
    Position?                    0
```

```text
-Jobs
    Specifies one or more task jobs or a hashtable with actual parameters.
    Jobs are other task references and own actions, script blocks. Any
    number of jobs is allowed. Jobs are invoked in the specified order.
    
    Valid jobs are:
    
        [string] - an existing task name, normal reference
        [string] "?Name" - safe reference to a task allowed to fail
        [scriptblock] - action, a script block invoked for this task
    
    Special value:
    
        [hashtable] which contains the actual task parameters in addition
        to the task name. This task definition is more convenient with
        complex parameters, often typical for incremental tasks.
    
        Example:
            task Name @{
                Inputs = {...}
                Outputs = {...}
                Partial = $true
                Jobs = {
                    process {...}
                }
            }
    
    Required?                    false
    Position?                    1
```

```text
-After
    Tells to add this task to the end of jobs of the specified tasks.
    
    Altered tasks are defined as normal references (TaskName) or safe
    references (?TaskName). In the latter case this inserted task may
    fail without stopping a build.
    
    Parameters After and Before are used in order to alter task jobs
    in special cases when direct changes in task source code are not
    suitable. Use Jobs in order to define relations in usual cases.
    
    Required?                    false
    Position?                    named
```

```text
-Before
    Tells to insert this task to jobs of the specified tasks.
    It is inserted before the first action or added to the end.
    
    See After for details.
    
    Required?                    false
    Position?                    named
```

```text
-Data
    Any object attached to the task. It is not used by the engine.
    When the task is invoked this object is available as $Task.Data.
    
    Required?                    false
    Position?                    named
```

```text
-Done
    Specifies the command or a script block which is invoked after the
    task. Custom handlers should check for $Task.Error if it matters.
    
    Required?                    false
    Position?                    named
```

```text
-If
    Specifies the optional condition to be evaluated. If the condition
    evaluates to false then the task is not invoked. The condition is
    defined in one of two ways depending on the requirements.
    
    Using standard Boolean notation (parenthesis) the condition is checked
    once when the task is defined. A use case for this notation might be
    evaluating a script parameter or another sort of global condition.
    
        Example:
            task Task1 -If ($Param1 -eq ...) {...}
            task Task2 -If ($PSVersionTable.PSVersion.Major -ge 5) {...}
    
    Using script block notation (curly braces) the condition is evaluated
    on task invocation. If a task is referenced by several tasks then the
    condition is evaluated each time until it gets true and the task is
    invoked. The script block notation is normally used for a condition
    that may be defined or changed during the build or just expensive.
    
        Example:
            task SomeTask -If {...} {...}
    
    Required?                    false
    Position?                    named
    Default value                $true
```

```text
-Inputs
    Specifies the input items, tells to process the task as incremental,
    and requires the parameter Outputs with the optional switch Partial.
    
    Inputs are file items or paths or a script block which gets them.
    
    Outputs are file paths or a script block which gets them.
    A script block is invoked with input paths piped to it.
    
    Automatic variables for incremental task actions:
    
        $Inputs - full input paths, array of strings
        $Outputs - result of the evaluated Outputs
    
    With the switch Partial the task is processed as partial incremental.
    There must be one-to-one correspondence between Inputs and Outputs.
    
    Partial task actions often contain "process {}" blocks.
    Two more automatic variables are available for them:
    
        $_ - full path of an input item
        $2 - corresponding output path
    
    See also docs about incremental tasks:
    https://github.com/nightroman/Invoke-Build/blob/main/Docs/README.md
    
    Required?                    false
    Position?                    named
```

```text
-Outputs
    Specifies the output paths of the incremental task, either directly on
    task creation or as a script block invoked with the task. It is used
    together with Inputs. See Inputs for details.
    
    Required?                    false
    Position?                    named
```

```text
-Partial
    Tells to process the incremental task as partial incremental.
    It is used with Inputs and Outputs. See Inputs for details.
    
    Required?                    false
    Position?                    named
```

```text
-Source
    Specifies the task source. It is used by wrapper functions in order to
    provide the actual source for location messages and synopsis comments.
    
    Required?                    false
    Position?                    named
```

## Examples

```text
-------------------------- EXAMPLE 1 --------------------------
PS>
# Dummy task with no jobs
task Task1

# Alias of another task
task Task2 Task1

# Combination of tasks
task Task3 Task1, Task2

# Simple action task
task Task4 {
    # action
}

# Typical complex task: referenced task(s) and one own action
task Task5 Task1, Task2, {
    # action after referenced tasks
}

# Possible complex task: actions and tasks in any required order
task Task6 {
    # action before Task1
},
Task1, {
    # action after Task1 and before Task2
},
Task2

This example shows various possible combinations of task jobs.
```

```text
-------------------------- EXAMPLE 2 --------------------------
PS>
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

Tasks with complex parameters are often difficult to compose in a readable
way. In such cases use a hashtable in order to specify task parameters in
addition to the task name. Keys and values correspond to parameter names
and values.
```

## Links

```text
Get-BuildError
Get-BuildSynopsis
```
