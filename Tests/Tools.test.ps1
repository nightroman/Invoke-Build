<#
.Synopsis
	Tests the module Tools.
#>

Import-Module .\Tools

task Assert-Compare {
	# OK
	Assert-Compare Left Left
	Assert-Compare Left, 42 Left, 42

	# KO
	$r = try { Assert-Compare Left Right } catch { $_ }
	Test-Error $r *Right*=>*Left*<=*

	# KO, cover SyncWindow 0
	$r = try { Assert-Compare Text, 42 42, Text } catch { $_ }
	Test-Error $r *42*=>*Text*<=*Text*=>*42*<=*
}

task Test-Error {
	# it should fail on no error ($null)
	# then use this error for next tests
	($r = try { Test-Error } catch { $_ })

	# 1st test by equals
	equals "$r" 'Expected error record.'

	# 2nd test by Test-Error wildcard
	Test-Error $r 'Expected error record.*'
}
