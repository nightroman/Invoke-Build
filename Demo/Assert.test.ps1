
<#
.Synopsis
	Tests 'assert' and $ErrorActionPreference.

.Example
	Invoke-Build * Assert.test.ps1
#>

# $ErrorActionPreference is 'Stop' by default.
assert ($ErrorActionPreference -eq 'Stop')

# But scripts can change this.
$ErrorActionPreference = 0

# Also check that $WhatIf is true on ?
assert (('?' -ne $BuildTask) -or $WhatIf)

# Assert does not require Boolean, any object will do.
assert "Hi!"
assert $Host

# Synopsis: Fail with the default message.
task AssertDefault {
	# Check $ErrorActionPreference
	assert ($ErrorActionPreference -eq 0)

	# Hack needed only for testing, change
	$script:ErrorActionPreference = 'Stop'

	# The simplest assert always fails
	assert
}

# This task fails with a custom message.
task AssertMessage {
	# Check $ErrorActionPreference and change it.
	assert ($ErrorActionPreference -eq 'Stop')
	$ErrorActionPreference = 0

	# Assert with a message.
	assert $false 'Custom assert message.'
}

# Synopsis: Call tests and check errors.
# Note use of safe references to failing tasks.
task . (job AssertDefault -Safe), (job AssertMessage -Safe), {
	# Check $ErrorActionPreference and change it.
	assert ($ErrorActionPreference -eq 'Stop')
	$ErrorActionPreference = 0

	# silly test
	assert $true

	$e = error AssertDefault
	assert ("$e" -eq 'Assertion failed.')

	$e = error AssertMessage
	assert ("$e" -eq 'Assertion failed. Custom assert message.')

	'assert is tested.'
}
