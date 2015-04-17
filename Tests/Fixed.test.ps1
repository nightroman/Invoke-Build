
<#
.Synopsis
	Assorted tests, fixed issues..

.Example
	Invoke-Build * Fixed.test.ps1
#>

Set-StrictMode -Version Latest

# Synopsis: v2.10.1 Fixed incomplete error on Safe.
task IncompleteErrorOnSafe {
	'task test { throw 42 }' > z.build.ps1
	($r = Invoke-Build * z.build.ps1 -Safe | Out-String)
	assert ($r -clike 'Build test*Task /test*At *\z.build.ps1:1*ERROR: 42*At *\z.build.ps1:1*')
	Remove-Item z.build.ps1
}

# Synopsis: #5 Invoke-Build ** -Safe propagates -Safe.
task SafeTests {
	Remove-Item [z] -Force -Recurse
	$null = mkdir z

	@'
; task task11 { 'works-11' }
; task task12 { throw 'oops-12' }
; task task23 { throw 'unexpected' }
'@ > z\1.test.ps1

	@'
; task task21 { 'works-21' }
; task task22 { throw 'oops-22' }
; task task23 { throw 'unexpected' }
'@ > z\2.test.ps1

	Invoke-Build ** z -Safe -Result r

	assert ($null -eq $r.Error)
	assert ($r.Errors.Count -eq 2)
	assert ($r.Tasks.Count -eq 4)
	assert ('oops-12' -eq $r.Tasks[1].Error)
	assert ('oops-22' -eq $r.Tasks[3].Error)

	Remove-Item z -Force -Recurse
}
