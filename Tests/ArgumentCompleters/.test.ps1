
. ../Shared.ps1

$Version = $PSVersionTable.PSVersion.Major

task TabExpansion2.v5 -If ($Version -ge 5) {
	#! work around Unix globbing: "'*'"
	exec {Invoke-PowerShell -NoProfile -Command Invoke-Build "'*'" TabExpansion2.v5.build.ps1}
}
