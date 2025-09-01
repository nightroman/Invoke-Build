
task TabExpansion2.v5 {
	#! work around Unix globbing: "'*'"
	exec {Invoke-PowerShell -NoProfile -Command Invoke-Build "'*'" TabExpansion2.v5.build.ps1}
}
