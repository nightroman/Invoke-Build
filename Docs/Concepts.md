# Concepts

Why are these build scripts? Why not just use normal scripts with functions
instead of scripts with tasks? This is a reasonable question and in many cases
scripts with functions is the right choice. But in some scenarios scripts with
tasks are easier to compose and use due to special conventions and features.

## Typical build script scenarios

There is a directory with files, a "project", "workspace", "repository", etc.
And there are operations on its files, "tasks". Tasks should be automated and
easily invoked individually or as combinations.

This is a typical scenario where a build script with tasks may have advantages
over a normal script with functions, especially if its location is the project
directory.

## The current location is known

The current location is always set to the build script directory. This is done
before invoking the script itself, tasks, conditions, inputs, outputs, blocks,
etc.

Due to this convention, tasks dealing with project files simply access them by
relative paths. Other scripts in the project are easily invoked by relative
paths, too. Tasks may change the current location and do not have to care
of restoring it.

This is not the case for normal scripts. The location of files has to be set
current manually or specified by a parameter or calculated. Invocation of
external scripts by relative paths also needs some coding. If a function
changes the current location then it may have to restore it for others.

## Tasks may have relations

Tasks may refer to other tasks to be invoked as well.
Task relations allow easy composition of complex task trees.
See [Show Build Graph](Show-Build-Graph.md) for examples.

A build script caller does not have to know all the relations. It calls the
tasks that should be done. Related tasks are discovered by the engine and
invoked in the proper order according to defined relations.

This is not the case for a set of functions in a normal script. All required
functions have to be known to a caller and invoked explicitly in a correct
order. This may be easy with a few functions but it is difficult and error
prone in complex scenarios with many related operations.

Of course, some functions may call other functions themselves, relations are
also possible, and a caller does not have to specify functions to be invoked
anyway. But...

## Tasks are invoked once

A task may be referenced many times by other tasks in the task trees being
built. But as soon as it is invoked, it is never invoked again in the same
build.

This is not the case with functions calling other functions. A function may be
called many times. As a result, without extra care it may do the same job more
than once. This is suboptimal performance in some cases and issues in others.

## Useful sanity checks

A build script is checked by the engine for missing referenced tasks and cyclic
references. If there is any then the build stops before invocation of tasks and
the problem is explained.

This is not the case for a normal script with functions. Problems like missing
functions and cyclic references are discovered somewhere in the middle of the
running process.

## Default error action Stop

The default PowerShell error action is *Continue*, so that non terminating
errors do not stop processing. This may be useful in interactive mode when
errors are analysed before typing next commands.

But in scripts *Continue* is simply dangerous. That is why the build engine
sets the default error action to *Stop* and build scripts may count on this.

This is not the case for a normal script. The current default error action is
unknown, it depends on various factors, and very likely it is the default not
safe *Continue*. Thus, normal scripts should take care of this.

## Handy features and tools

Invocation of build scripts comes with simple and yet useful logging, with
colors in a console, task duration measurement, processing of failures with
shown error messages and task locations. Warnings are collected and shown
separately after a build.

Incremental tasks provide effective ways to process files with out of date
output and skip files with up to date output.

The build engine provides a few helper commands. Build scripts may use them in
order to avoid some tedious coding.

- `exec` invokes an application and checks for exit code.
- `assert` tests a condition and fails if it is not true.
- `equals` verifies that two specified objects are equal.
- `remove` removes the specified temporary build items.
- `print` writes text with host colors, when possible.
- `property` gets a session or environment variable.
- `requires` checks for the required build assets.
- `use` creates aliases to often used tools.

## Active documentation

Build script tasks naturally describe what actions are supposed to be performed
for a project, even if they are not documented explicitly. Supportive tools get
this information in various ways.

- `Invoke-Build ?` shows available tasks with jobs and optional synopses from comments.
- `Invoke-Build ... -WhatIf` gets more detailed preview of tasks and jobs to be invoked.
- `Show-BuildGraph`, `Show-BuildMermaid.ps1`, `Show-BuildDgml` show task graphs.
- `Show-BuildTree` shows task trees as text.
