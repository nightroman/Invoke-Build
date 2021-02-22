# This script shows how build headers and footers are inherited.
# It is supposed to be called by 1.build.ps1 which sets them.

# Synopsis: Child task description 1.
task ChildTask1 {
	'some output 1'
}

# Synopsis: Child task description 2.
task ChildTask2 {
	'some output 2'
}
