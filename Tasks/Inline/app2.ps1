<#
.Synopsis
	Import a build and set build blocks.
#>

Invoke-Build Test {
	# import build script
	. ./my.build.ps1

	# set build block
	Set-BuildHeader {
		param($Path)
		print Cyan "Task $Path"
		print Magenta "# Synopsis: $(Get-BuildSynopsis $Task)"
	}
}
