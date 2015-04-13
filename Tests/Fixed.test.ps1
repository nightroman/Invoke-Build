
# Synopsis: v2.10.1 Fixed incomplete error on Safe.
task IncompleteErrorOnSafe {
	'task test { throw 42 }' > z.build.ps1
	($r = Invoke-Build * z.build.ps1 -Safe | Out-String)
	assert ($r -clike 'Build test*Task /test*At *\z.build.ps1:1*ERROR: 42*At *\z.build.ps1:1*')
	Remove-Item z.build.ps1
}
