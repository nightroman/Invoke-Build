<#
	Build script for testing Build-JustTask.ps1
#>

# Flags of invoked tasks. The test script makes its own variable.
if (!(Test-Path Variable:\BuildJustTask)) {
	$BuildJustTask = @{
		t1 = 0
		t2 = 0
		t3 = 0
		t4 = 0
	}
}

# Show the result flags on exiting.
Exit-Build {
	$BuildJustTask.GetEnumerator() | Sort-Object Key | Out-String
}

task t1 {$BuildJustTask.t1 = 1}

task t2 t1, {$BuildJustTask.t2 = 1}, t3

task t3 t1, {$BuildJustTask.t3 = 1}

task t4 t1, t3, {$BuildJustTask.t4 = 1}
