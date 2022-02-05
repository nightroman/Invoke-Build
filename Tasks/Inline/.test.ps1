
Enter-BuildJob {
	$log = New-Object System.IO.StringWriter
	function Write-Host {
		param($Object)
		$Object
		$log.Write($Object)
	}
}

task app1 {
	.\app1.ps1
	equals $log.ToString() '@BeforeTest@Test@AfterTest'
}

task app2 {
	($r = .\app2.ps1)
	equals $log.ToString() '@Test'
	assert ($r -like '*# Synopsis: Some task.*')
}

task app3 {
	($r = .\app3.ps1)
	assert ($r[-4] -like '*Build summary:*')
	assert ($r[-3] -like '*00:00:00* TestBuildFile - *app3.ps1:*')
	assert ($r[-2] -like '*00:00:00* TestBuildRoot - *app3.ps1:*')
}
