<#
	Tests Build-JustTask.ps1
#>

function New-TestData {
	@{
		t1 = 0
		t2 = 0
		t3 = 0
		t4 = 0
	}
}

task Just2 {
	$BuildJustTask = New-TestData
	Build-JustTask t2
	equals 0 $BuildJustTask.t1
	equals 1 $BuildJustTask.t2
	equals 0 $BuildJustTask.t3
	equals 0 $BuildJustTask.t4
}

task Just3 {
	$BuildJustTask = New-TestData
	Build-JustTask t3
	equals 0 $BuildJustTask.t1
	equals 0 $BuildJustTask.t2
	equals 1 $BuildJustTask.t3
	equals 0 $BuildJustTask.t4
}

task Just2And4 {
	$BuildJustTask = New-TestData
	Build-JustTask t2, t4
	equals 0 $BuildJustTask.t1
	equals 1 $BuildJustTask.t2
	equals 0 $BuildJustTask.t3
	equals 1 $BuildJustTask.t4
}
