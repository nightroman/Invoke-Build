
This sample demonstrates two techniques:

- Import tasks from all conventional task scripts.
- Use `requires` in task scripts to declare their assets.

The main build script `.build.ps1` imports tasks from several external task
scripts. In this case, all found `*.tasks.ps1` are imported by dot-sourcing.
In practice, where to get such files and how to name them is up to authors.

Each sample `*.tasks.ps1` specifies assets of different types by `requires`.
In practice, assets of different types may be used together.
