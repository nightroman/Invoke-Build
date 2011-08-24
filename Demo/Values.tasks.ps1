
<#
.Synopsis
	Example of a scripts with an imported task and data (like MSBuild *.targets)

.Description
	See .build.ps1, line with . .\Values.tasks.ps1 and comments there.
#>

$MySharedValue1 = 'shared 1'

task SharedValueTask1 {
	'SharedValueTask1'

	# test: the value is available
	assert (Test-Path Variable:\MySharedValue1)

	# use the value
	"MySharedValue1='$MySharedValue1'"
}
