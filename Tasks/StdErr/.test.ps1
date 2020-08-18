
if ($PSVersionTable['Platform'] -eq 'Unix') {return task unix}
$Version = $PSVersionTable.PSVersion.Major

task TestProblem {
	try {
		Invoke-Build Problem 2> z.log
		throw 'done'
	}
	catch {
		if ($Version -ge 7) {
			equals "$_" done
		}
		else {
			equals "$_" 'standard error '
		}
	}

	$r = Get-Content z.log
	if ($Version -ge 7) {
		equals $r 'standard error '
	}
	else {
		equals $r $null
	}

	Remove-Item z.log
}

task TestWorkaround {
	Invoke-Build Workaround 2> z.log

	$r = Get-Content z.log
	if ($Version -ge 7) {
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
		equals "$_" 'Command {./error2.cmd} exited with code 42.'
	}

	$r = Get-Content z.log
	if ($Version -ge 7) {
		equals $r 'standard error '
	}
	else {
		equals $r[0] './error2.cmd : standard error '
	}

	Remove-Item z.log
}
