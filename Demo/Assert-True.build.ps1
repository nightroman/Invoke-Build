
<#
.Synopsis
	Assert-True (assert) tests.

.Description
	Assert-True does not allow not Boolean condition values. Yes, in many cases
	implicit cast to Boolean would be handy. But in some cases that would be
	error prone.

	Say, curly brackets are used instead of parentheses by mistake:

		assert { ... }

	This assertion never fails because { ... } is a script block, not null
	object, which is always converted to $true where Boolean is needed, try:

		[bool]{ $false }

.Link
	Invoke-Build
	.build.ps1
#>

# This task fails with a default message.
task AssertDefault {
	assert $false
}

# This task fails with a custom message.
task AssertMessage {
	assert $false 'Custom assert message.'
}

# This task fails, there is no arguments.
task AssertInvalid1 {
	assert
}

# This task fails, the argument is not a Boolean value.
task AssertInvalid2 {
	assert ([bool]$Host) # this is correct
	assert ($null -ne $Host) # this is correct
	assert $Host # this is not correct and fails
}

# The default task calls the others and tests the result errors.
# Note use of @{} for failing tasks.
task . @{AssertDefault=1}, @{AssertMessage=1}, @{AssertInvalid1=1}, @{AssertInvalid2=1}, {
	# silly test
	assert $true

	$e = Get-Error AssertDefault
	assert ("$e" -eq 'Assertion failed.')

	$e = Get-Error AssertMessage
	assert ("$e" -eq 'Custom assert message.')

	$e = Get-Error AssertInvalid1
	assert ("$e" -eq 'Condition is not Boolean.')

	$e = Get-Error AssertInvalid2
	assert ("$e" -eq 'Condition is not Boolean.')

	'Tested Assert-True.'
}
