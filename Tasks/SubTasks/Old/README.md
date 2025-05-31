# Sub tasks technique

**OBSOLETE: Consider using [New](../New) build script inheritance technique**

The original idea and discussion [#177](https://github.com/nightroman/Invoke-Build/issues/177)
by [@dsbenghe](https://github.com/dsbenghe)

The "build system" consists of the root script [root.build.ps1](root.build.ps1)
and child build scripts, two in this demo:
[deploy/deploy.build.ps1](deploy/deploy.build.ps1) and [src/build.build.ps1](src/build.build.ps1):

- `root.build.ps1`
- `deploy/`
    - `deploy.build.ps1`
- `src/`
    - `build.build.ps1`

The root build script is designed for direct calls, see [Direct](../../Direct).
It contains the usual tasks and two special tasks `build` and `deploy` which call child build scripts.

The first parameter `Tasks` specifies either root tasks or the special `build` or `deploy`.
In the latter case, the second parameter `SubTasks` specifies tasks in the correspondent build script.

See [.test.ps1](.test.ps1) for examples.

## Dynamic sub parameters

The root script defines its parameters and does not include parameters of child scripts.
Yet, if one of the special tasks `build` or `deploy` is specified then the correspondent
child parameters are dynamically available for invoking and completion.

Example:

    ./root.build.ps1 build task1 -[TAB]

provides the following completions (root and child parameters):

    RootParam1
    BuildParam1
    BuildParam2
    CommonChildParam
    ...

## Sub tasks completion

The root script parameter `SubTasks` comes with the attribute `ArgumentCompleter`.
This attribute defines completion of sub tasks in the command line.

Example:

    ./root.build.ps1 build [TAB]

provides the following completions (child script tasks):

    task1
    build-task2
    .
