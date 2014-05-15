
<#
.Synopsis
	The task Sleep is used to simulate time consuming jobs.
#>

param
(
	$Milliseconds
)

task Sleep {
	'begin - начало'
	Start-Sleep -Milliseconds $Milliseconds
	'end - конец'
}
