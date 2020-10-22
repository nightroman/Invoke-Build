
. ../Shared.ps1
if ($IsUnix) {return task unix}

$Version = $PSVersionTable.PSVersion.Major

task TabExpansion2.v5 -If ($Version -ge 5) {
	exec {Invoke-PowerShell -NoProfile -Command Invoke-Build * TabExpansion2.v5.build.ps1}
}
