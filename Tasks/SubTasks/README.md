# Sub tasks technique

The original idea and discussion [#177](https://github.com/nightroman/Invoke-Build/issues/177)
by [@dsbenghe](https://github.com/dsbenghe)

The "build system" consists of the root build script and several child build scripts:

```
|   root.build.ps1
|
+---deploy
|       deploy.build.ps1
|
\---src
        build.build.ps1
```

The root build script is designed for direct calls, see [Direct](../Direct).
It contains the usual tasks and two special tasks `build` and `deploy` which call child build scripts.

The first parameter `Tasks` specifies either root tasks or the special `build` or `deploy`.
In the latter case, the second parameter `SubTasks` specifies tasks in the correspondent build script.

See [.test.ps1](.test.ps1) for examples.


## Dynamic sub parameters

The root script defines its parameters and does not include parameters of child scripts.
Yet, if one the special tasks `build` or `deploy` is specified then the correspondent
child parameters are dynamically available for invoking or code completion.

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
This attributes defines completion of sub tasks in the command line.

Example:

    ./root.build.ps1 build [TAB]

should provide the following completions (child script tasks):

    task1
    build-task2
    .
