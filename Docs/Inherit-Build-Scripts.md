# Inherit Build Scripts

**New feature: Build script inheritance**

> Consider as preview in v5.14.x

The build script parameter `Extends` with `ValidateScript` tells to
dot-source base scripts, replace `Extends` with base parameters, and
optionally rename base tasks.

Multiple and multilevel inheritance is supported, `ValidateScript` may specify
any number of scripts and these scripts may use `Extends` recursively.

Documentation and examples: [Tasks/Extends](https://github.com/nightroman/Invoke-Build/tree/main/Tasks/Extends)
