
<#
.Synopsis
	Example of a test script.

.Description
	This script is a demo of the custom test-task.
	See "Test.tasks.ps1" for the details of "test".

.Example
	Invoke-Build * Test.build.ps1
#>

# Import test-task definitions.
. .\Test.tasks.ps1

# Synopsis: This test works.
test FirstTestWorks {
	"Test $($Task.Name) works."
}

# Synopsis: This test fails.
test SecondTestFails {
	throw "Demo error in '$($Task.Name)'."
}

# Synopsis: This task is referenced by a test and fails.
task RefTaskFails {
	throw "Demo error in '$($Task.Name)'."
}

# Synopsis: This test is referenced by a test and fails.
test RefTestFails {
	throw "Demo error in '$($Task.Name)'."
}

# Synopsis: This test fails due to errors in references.
test testFailsDueToReference RefTaskFails, RefTestFails, {
	assert 0 "This should not be invoked."
}

# Synopsis: This task is referenced by a test and works.
task RefTaskWorks {
	"Test $($Task.Name) works."
}

# Synopsis: This test is referenced by a test and works.
test RefTestWorks {
	"Test $($Task.Name) works."
}

# Synopsis: This test with references works.
test testWithReferenceWorks RefTaskWorks, RefTestWorks, {
	"Test $($Task.Name) works."
}

# Synopsis: This test works.
test LastTestWorks {
	"Test $($Task.Name) works."
}
