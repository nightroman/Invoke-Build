
if ($PSVersionTable['Platform'] -eq 'Unix') {return task unix}
$Version = [version]$PSVersionTable.PSVersion
${7.2.0} = [version]'7.2.0'
${7.1.2} = [version]'7.1.2'

task TestProblem {
	try {
		Invoke-Build Problem
		throw 'done'
	}
	catch {
		if ($Version -ge ${7.2.0}) {
			equals "$_" done # expected
		}
		else {
			equals "$_" 'standard error '
		}
	}
}

task TestWorkarounds {
	Invoke-Build Workaround1
	Invoke-Build Workaround2
}

task TestWorkaround2 {
	try {
		Invoke-Build NonZeroExitCode
		throw
	}
	catch {
		equals "$_" 'Command exited with code 42. { ./error2.cmd 2>$null }'
	}
}

### Using the switch -StdErr, v5.11.0

task StdErr_ZeroExitCode {
	$r = Invoke-Build StdErr_ZeroExitCode
	($r = $r -join '|')
	assert $r.Contains('|standard output|standard error |')
}

task StdErr_NonZeroExitCode {
	try {
		throw Invoke-Build StdErr_NonZeroExitCode
	}
	catch {
		($r = "$_")
		assert $r.Contains('Command exited with code 42. { ./error2.cmd }')
		assert $r.Contains('standard error ')
	}
}
