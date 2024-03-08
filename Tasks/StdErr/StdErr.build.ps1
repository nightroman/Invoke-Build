
# This task "unexpectedly" fails due to standard error output (Desktop, works fine in latest Core).
task Problem {
	exec { ./error1.cmd 2>$null }
}

# The workaround makes the problem task working.
task Workaround1 {
	exec {
		$ErrorActionPreference = 'Continue'
		./error1.cmd 2>$null
	}
}

# The workaround makes the problem task working.
task Workaround2 {
	exec { ./error1.cmd 2>$null } -ErrorAction Continue
}

# Exec still fails on non zero exit codes.
task NonZeroExitCode {
	exec { ./error2.cmd 2>$null } -ErrorAction Continue
}

### Using the switch -StdErr, v5.11.0

# In this case we do not usually redirect or discard standard errors. Errors
# are automatically turned into standard output and also used for enhancing
# error messages when commands exit with failure codes.

# This works and outputs standard errors as strings.
task StdErr_ZeroExitCode {
	exec { ./error1.cmd } -StdErr
}

# This fails and the error contains standard errors.
task StdErr_NonZeroExitCode {
	exec { ./error2.cmd } -StdErr
}
