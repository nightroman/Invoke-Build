# Examples, patterns, techniques

## Featured

- [Extends](Extends) How build script inheritance extends dot-sourcing.

## Techniques

- [01-step-by-step-tutorial](01-step-by-step-tutorial) - From "Hello world" to featured script.
- [Attributes](Attributes) How to use custom attributes with task actions.
- [Bootstrap](Bootstrap) How to install the module automatically.
- [Confirm](Confirm) How to use `Confirm-Build` to confirm some tasks.
- [Direct](Direct) How to make build scripts invokable directly.
- [Direct-2](Direct-2) How to make build scripts invokable directly (variant 2).
- [Dynamic](Dynamic) How to use a dynamic script with dynamic tasks.
- [Extends](Extends) How build script inheritance extends dot-sourcing.
- [Header](Header) How to define custom task headers and footers.
- [Import](Import) How to share and import tasks from external task scripts including exported by modules.
- [Inline](Inline) How to assemble a whole build inline as a script block without creating an extra script.
- [Logging](Logging) How to log build output.
- [Paket](Paket) Build script with automatic bootstrapping using `paket`.
- [Param](Param) How to create tasks which perform similar actions with some differences defined by parameters.
- [StdErr](StdErr) Dealing with standard error output issues.
- [Steps][Steps] Tasks as steps, interactive, persistent, ...
- [SubCases](SubCases) Sub cases in child scripts technique.
- [SubTasks](SubTasks) Sub tasks in child scripts technique.

## Custom tasks

Custom tasks may be defined literally and via custom parameters, see [Repeat](Repeat) and [Repeat2](Repeat2).

- [Check](Check) shows the custom task `check` which is invoked once even if a build (check list) is invoked repeatedly.
- [File](File) shows the custom task `file`, an incremental task with simplified syntax, somewhat similar to Rake's `file`.
- [Repeat](Repeat) shows the custom task `repeat` which is invoked periodically in a build script (schedule) with such tasks.
- [Repeat2](Repeat2) shows the alternative way with using the special command `repeat` which turns tasks into repeatable.
- [RepeatRedis](RepeatRedis) is similar to `Repeat2` but it uses Redis for task records instead of CLIXML files.
- [Retry](Retry) shows the custom task `retry` which retries its action on failures several times depending on parameters.

## Known issues

- [Bugs](Bugs) Known issues and workarounds.
