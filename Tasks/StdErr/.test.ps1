
if ($PSVersionTable['Platform'] -eq 'Unix') {return task unix}
$Version = [version]$PSVersionTable.PSVersion
${7.2.0} = [version]'7.2.0'
${7.1.2} = [version]'7.1.2'

task TestProblem {
	try {
		Invoke-Build Problem 2> z.log
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

	$r = Get-Content z.log
	if ($Version -ge ${7.2.0}) {
		equals $r 'standard error ' # expected
	}
	else {
		equals $r $null
	}

	Remove-Item z.log
}

task TestWorkaround {
	Invoke-Build Workaround 2> z.log

	($r = Get-Content z.log)
	# latest
	if ($Version -ge ${7.2.0}) {
		equals $r 'standard error '
	}
	# GHA
	elseif ($Version -ge ${7.1.2}) {
		equals $r 'standard error '
	}
	else {
		equals $r[0] './error1.cmd : standard error '
	}

	Remove-Item z.log
}

task TestWorkaround2 {
	try {
		Invoke-Build Workaround2 2> z.log
		throw
	}
	catch {
		equals "$_" 'Command exited with code 42. {./error2.cmd}'
	}

	($r = Get-Content z.log)
	# latest
	if ($Version -ge ${7.2.0}) {
		equals $r 'standard error '
	}
	# GHA
	elseif ($Version -ge ${7.1.2}) {
		equals $r 'standard error '
	}
	else {
		equals $r[0] './error2.cmd : standard error '
	}

	Remove-Item z.log
}
