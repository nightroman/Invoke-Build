# Samples, patterns, techniques

## Techniques

- [Attributes](Attributes) How to use custom attributes with task actions.
- [Direct](Direct) How to make build scripts invokable directly.
- [Dynamic](Dynamic) How to use a dynamic script with dynamic tasks.
- [Header](Header) How to define custom task headers and footers.
- [Import](Import) How to share and import tasks from external task scripts including exported by modules.
- [Inline](Inline) How to assemble a whole build inline as a script block without creating an extra script.
- [Paket](Paket) Build script with automatic bootstrapping using `paket`.
- [Param](Param) How to create tasks which perform similar actions with some differences defined by parameters.
- [StdErr](StdErr) Dealing with standard error output issues.
- [SubTasks](SubTasks) Sub tasks in child scripts technique.

## Custom tasks

- [Ask](Ask) shows the custom task `ask` which asks for the confirmation.
- [Check](Check) shows the custom task `check` which is invoked once even if a build script (check list) is invoked repeatedly.
- [File](File) shows the custom task `file`, an incremental task with simplified syntax, somewhat similar to Rake's `file`.
- [Repeat](Repeat) shows the custom task `repeat` which is invoked periodically in a build script (schedule) with such tasks.
- [Retry](Retry) shows the custom task `retry` which retries its action on failures several times depending on parameters.

## Known issues

- [Problematic `:` in dynamic `-Param:Value`](Bugs/DynamicParamColon)
- [Dynamic switch parameter issue](Bugs/DynamicParamSwitch)
