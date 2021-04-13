#!/bin/bash

# Link to this from /usr/local/bin to be able to call invoke-build directly from bash.
# Example:
# ln -s .../ib.sh /usr/local/bin/ib
# chmod +x /usr/local/bin/ib
# ib task1, task2

if [ $# -gt 0 ]
then
    pwsh -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Build $@"
else
    pwsh -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Build"
fi
