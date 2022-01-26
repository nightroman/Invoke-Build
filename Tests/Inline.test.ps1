<#
.Synopsis
	Tests samples Tasks/Inline

.Example
	Invoke-Build * Inline.test.ps1
#>

. ./Shared.ps1

Enter-BuildJob {
	$log = New-Object System.IO.StringWriter
	. Set-Mock Write-Host {param($Object)
		$Object
		$log.Write($Object)
	}
}

task app1 {
	../Tasks/Inline/app1.ps1
	equals $log.ToString() '@BeforeTest@Test@AfterTest'
}

task app2 {
	($r = ../Tasks/Inline/app2.ps1)
	$r = Remove-Ansi $r
	equals $log.ToString() '@Test'
	assert ($r -contains '# Synopsis: Some task.')
}

task app3 {
	($r = ../Tasks/Inline/app3.ps1)
	$r = Remove-Ansi $r
	equals $r[-4] 'Build summary:'
	assert ($r[-3] -like '00:00:00* TestBuildFile - *app3.ps1:*')
	assert ($r[-2] -like '00:00:00* TestBuildRoot - *app3.ps1:*')
}
