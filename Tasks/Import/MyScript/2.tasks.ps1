
# Tell to test the required environment variable.
requires -Environment MyEnv1

# Synopsis: Some task with an environment variable.
task MyEnv {
	# just show the value
	"MyEnv1 = $env:MyEnv1"
}
