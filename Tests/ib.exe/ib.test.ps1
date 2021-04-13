
if ($env:GITHUB_ACTION) {return task skip_GITHUB_ACTION}

task helpText {
	$r = exec { ib.exe -h }
	equals $r[0] 'The following commands and options are supported:'

	$r = exec { ib.exe --help }
	equals $r[0] 'The following commands and options are supported:'
}

task helpCommand {
	$r = exec { ib.exe -h assert }
	equals $r[1] NAME
	equals $r[2] '    Assert-Build'

	$r = exec { ib.exe --help assert }
	equals $r[1] NAME
	equals $r[2] '    Assert-Build'
}

task helpInvokeBuild {
	$r = exec { ib.exe -? }
	equals $r[1] NAME
	equals $r[2] '    Invoke-Build.ps1'

	$r = exec { ib.exe /? }
	equals $r[1] NAME
	equals $r[2] '    Invoke-Build.ps1'
}

task powershell {
	($r = exec { ib.exe version } | Out-String)
	assert ($r -match 'PSVersion=([\d\.]+)')
	assert ([version]$Matches[1]).Major 5
}

task pwsh -If (Get-Command pwsh -ErrorAction 0) {
	($r = exec { ib.exe --pwsh version } | Out-String)
	assert ($r -match 'PSVersion=([\d\.]+)')
	assert ([version]$Matches[1]).Major 7
}

task param {
	($r = exec { ib.exe 'version,' param -p1 'with space' -p2 "'apos'" -s1 } | Out-String)

	# task version
	assert ($r -match 'PSVersion=([\d\.]+)')
	assert ([version]$Matches[1]).Major 5

	# task param
	assert ($r -match "\bp1=with space\b")
	assert ($r -match "\bp2='apos'")
	assert ($r -match '\bs1=True\b')
	assert ($r -match '\bs2=False\b')
}
