
# This task "unexpectedly" fails due to standard error output.
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
