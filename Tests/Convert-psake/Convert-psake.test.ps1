
<#
.Synopsis
	Tests Convert-psake.ps1
#>

# Synopsis: Invoke Convert-psake.ps1. Output is to be compared.
task Convert-psake -If ($PSVersionTable.PSVersion.Major -ge 3) {
	Convert-psake default.ps1 -Invoke -Synopsis
}
