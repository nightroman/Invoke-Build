
<#
.Synopsis
	The task Sleep is used to simulate time consuming jobs.
#>

param
(
	$Milliseconds
)

task Sleep {
	'begin'
	Start-Sleep -Milliseconds $Milliseconds
	'end'
}
