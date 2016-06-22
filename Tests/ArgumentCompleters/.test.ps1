
$Version = $PSVersionTable.PSVersion.Major

task TabExpansion2.v5 -If ($Version -ge 5) {
	exec {ib.cmd * TabExpansion2.v5.build.ps1}
}

task TabExpansionPlusPlus -If ($Version -ge 3) {
	if (Get-Module TabExpansionPlusPlus -ListAvailable) {
		exec {ib.cmd * TabExpansionPlusPlus.build.ps1}
	}
	else {
		Write-Warning 'Missing module TabExpansionPlusPlus'
	}
}
