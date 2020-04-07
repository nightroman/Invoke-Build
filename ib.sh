#!/bin/bash

# link to this from /usr/local/bin to be able to call invoke-build directly from bash:

# example
# ln -s ~/.local/share/powershell/Modules/InvokeBuild/5.5.3/ib.sh /usr/local/bin/ib
# chmod +x /usr/local/bin/ib
# ib task1,task2

if [ $# -gt 0 ]
then
    pwsh -nologo -noprofile -noninteractive -executionPolicy bypass -command "invoke-build $@"
else
    pwsh -nologo -noprofile -noninteractive -executionPolicy bypass -command "invoke-build"
fi
