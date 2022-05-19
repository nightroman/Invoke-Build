
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
