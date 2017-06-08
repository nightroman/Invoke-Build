
# Tell to test the required variable.
requires MyModuleParam

# Some script scope stuff.
$MyExtraStuff = 'stuff1'

# Synopsis: Some task provided by the module.
task MyModuleTask {
	# call some module stuff
	Invoke-MyModuleStuff $MyModuleParam

	# use some extra stuff
	"MyExtraStuff = $MyExtraStuff"
}
