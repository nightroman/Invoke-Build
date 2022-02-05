<#
.Synopsis
	Tests 'equals'.
#>

task WhyEquals {
	# The goal is to make sure $x is equal to expected 2.
	# Suppose instead of 2 we get unexpected 2, 3 in $x
	$x = 2, 3

	# This assert passes because -eq gets 2 for this array
	assert ($x -eq 2)

	# The reversed comparison helps in this case
	#   assert (2 -eq $x)
	# But the message "Assertion failed." is not useful and the trick is easy
	# to forget. Also, in others cases PowerShell may convert something to 2.
	$r = try { assert (2 -eq $x) } catch {$_}
	"$r"

	# Thus, a better check would be
	#   assert $x.Equals(2)
	# The message is still not useful: "Assertion failed."
	# We can add a custom message but this becomes tedious.
	$r = try { assert $x.Equals(2) } catch {$_}
	"$r"

	# In many cases it is better to use equals
	#   equals $x 2
	# It fails as expected and its message is clear
	#   Objects are not equal:
	#   A: 2 3 [System.Object[]]
	#   B: 2 [int]
	$r = try { equals $x 2 } catch {$_}
	"$r"
}

task Null {
	equals $null
	equals $null $null
}

task Refs {
	equals $Host $Host
}

task NullX {
	($r = try {equals $null x} catch {$_})
	equals $r.FullyQualifiedErrorId Assert-BuildEquals
	assert ("$r" -match '^Objects are not equal:\r?\nA:\r?\nB: x \[string\]$')
}

task XNull {
	($r = try {equals x $null} catch {$_})
	equals $r.FullyQualifiedErrorId Assert-BuildEquals
	assert ("$r" -match '^Objects are not equal:\r?\nA: x \[string\]\r?\nB:$')
}

task IntString {
	($r = try {equals 1 '1'} catch {$_})
	equals $r.FullyQualifiedErrorId Assert-BuildEquals
	assert ("$r" -match '^Objects are not equal:\r?\nA: 1 \[int\]\r?\nB: 1 \[string\]$')
}

task CaseSensitive {
	($r = try {equals ps PS} catch {$_})
	equals $r.FullyQualifiedErrorId Assert-BuildEquals
	assert ("$r" -match '^Objects are not equal:\r?\nA: ps \[string\]\r?\nB: PS \[string\]$')
}
