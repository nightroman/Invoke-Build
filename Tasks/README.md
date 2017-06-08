
## Samples, patterns, techniques

**Techniques**

- [Direct](Direct) shows how to make build scripts invokable directly.
- [Import](Import) shows how to share and import tasks from external task scripts including exported by modules.
- [Param](Param) shows how to create tasks which perform similar actions with some differences defined by parameters.

**Custom tasks**

- [Ask](Ask) shows the custom task `ask` which asks for the confirmation.
- [Check](Check) shows the custom task `check` which is invoked once even if a build script (check list) is invoked repeatedly.
- [File](File) shows the custom task `file`, an incremental task with simplified syntax, somewhat similar to Rake's `file`.
- [Repeat](Repeat) shows the custom task `repeat` which is invoked periodically in a build script (schedule) with such tasks.
- [Retry](Retry) shows the custom task `retry` which retries its action on failures several times depending on parameters.
- [Test](Test) shows the custom task `test` which is allowed to fail without stopping a build.
