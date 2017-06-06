
# Tell to test the required session or environment variables.
requires -Property MyProp1, MyProp2

# Synopsis: Some task with session or environment variables.
task MyProp {
	# get values by `property`
	$MyProp1 = property MyProp1
	$MyProp2 = property MyProp2

	# just show the values
	"MyProp1 = $MyProp1"
	"MyProp2 = $MyProp2"
}
