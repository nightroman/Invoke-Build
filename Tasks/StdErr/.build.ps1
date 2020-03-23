
# This task "unexpectedly" fails due to standard error output.
task Problem {
	exec {./error1.cmd}
}

# The workaround makes the above task working fine.
task Workaround {
	exec {./error1.cmd} -ErrorAction Continue
}

# Exec still fails on non zero exit codes.
task Workaround2 {
	exec {./error2.cmd} -ErrorAction Continue
}
