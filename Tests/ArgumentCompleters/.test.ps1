
. ../Shared.ps1
if ($IsUnix) {return task unix}

$Version = $PSVersionTable.PSVersion.Major

task TabExpansion2.v5 -If ($Version -ge 5) {
	exec {Invoke-PowerShell -NoProfile -Command Invoke-Build * TabExpansion2.v5.build.ps1}
}

task TabExpansionPlusPlus -If ($Version -ge 3) {
	if (Get-Module TabExpansionPlusPlus -ListAvailable) {
		exec {Invoke-PowerShell -NoProfile -Command Invoke-Build * TabExpansionPlusPlus.build.ps1}
	}
	else {
		Write-Warning 'Missing module TabExpansionPlusPlus'
	}
}
