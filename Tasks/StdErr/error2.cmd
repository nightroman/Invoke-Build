:: an app with standard and error output and non zero exit code
@echo off
echo standard output
echo standard error 1>&2
exit /b 42
