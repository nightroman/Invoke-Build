
How to create several tasks which perform similar actions with some differences
depending on parameters?

The script *Param.build.ps1* shows two approaches, a simple with a function and
an advanced with a custom task. This is not about pros and cons, just examples
of different techniques.

A custom task is defined in the script *Param.task.ps1*. It does not have to be
a separate script, it can be a function defined right in *Param.build.ps1*. A
script makes sense as a library for use in several build scripts.
