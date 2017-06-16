
<#
.Synopsis
	Import a build and alter tasks.
#>

Invoke-Build Test {
	# import build script
	. ./my.build.ps1

	# alter task `Test`
	task BeforeTest -Before Test {
		Write-Host '@BeforeTest'
	}

	# alter task `Test`
	task AfterTest -After Test {
		Write-Host '@AfterTest'
	}
}
