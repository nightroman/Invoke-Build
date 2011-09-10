
<#
.Synopsis
	Assert tests.

.Example
	Invoke-Build . Assert.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

# This task fails with a default message.
task AssertDefault {
	assert
}

# This task fails with a custom message.
task AssertMessage {
	assert $false 'Custom assert message.'
}

# The default task calls the others and tests the result errors.
# Note use of @{Task=1} references to failing tasks.
task . @{AssertDefault=1}, @{AssertMessage=1}, {
	# silly test
	assert $true

	$e = error AssertDefault
	assert ("$e" -eq 'Assertion failed.')

	$e = error AssertMessage
	assert ("$e" -eq 'Assertion failed: Custom assert message.')

	'assert is tested.'
}
