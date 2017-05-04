
*Ask.tasks.ps1* defines the custom task `ask` which asks for the confirmation.
If a user chooses "No" then the task is skipped as if its `If` parameter gets
false, i.e. together with referenced tasks.

The build script *Ask.build.ps1* demonstrates `ask` tasks.
