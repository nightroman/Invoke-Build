
<#
.Synopsis
	Example of a scripts with an imported task and data (like MSBuild *.targets)

.Description
	See .build.ps1, line with . .\Values.tasks.ps1 and comments there.
#>

$SharedValue1 = 'shared 1'

task SharedValueTask1 {
	'SharedValueTask1'

	# test: the value is available
	if (!(Get-Variable SharedValue1)) { throw }

	# use the value
	"SharedValue1='$SharedValue1'"
}
