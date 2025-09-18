<#
.Synopsis
	Demo build script for New-VSCodeTask.ps1 tests
#>

task Build {
	'Hello from Build'
}

task Test {
	'Hello from Test'
}

task . Build, Test
