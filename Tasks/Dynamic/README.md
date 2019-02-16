
## Dynamic script with dynamic tasks

This sample shows how to dynamically generate several similar tasks. It also
uses a nested call to `Invoke-Build` with a dynamic script, so that generated
tasks do not "pollute" the main script.

The original problem: [Partial incremental tasks with > 1 (discovered) input per output](https://github.com/nightroman/Invoke-Build/issues/141)
