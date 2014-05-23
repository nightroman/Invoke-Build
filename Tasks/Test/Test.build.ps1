
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
	'Test FirstTestWorks works.'
}

# Synopsis: This test fails.
test SecondTestFails {
	throw 'Demo error in SecondTestFails.'
}

# Synopsis: This test is referenced by a test and fails.
test RefTestFails {
	throw 'Demo error in RefTestFails.'
}

# Synopsis: This test fails due to errors in references.
test RefTestFails2 RefTestFails, {
	assert 0 'This should not be invoked.'
}

# Synopsis: This test fails due to errors in references.
test RefTestFails3 RefTestFails2, {
	assert 0 'This should not be invoked.'
}

# Synopsis: This task is referenced by a test and works.
task RefTaskWorks {
	'Test RefTaskWorks works.'
}

# Synopsis: This test is referenced by a test and works.
test RefTestWorks {
	'Test RefTestWorks works.'
}

# Synopsis: This test with references works.
test TestWithRefsWorks RefTaskWorks, RefTestWorks, {
	'Test TestWithRefsWorks works.'
}
