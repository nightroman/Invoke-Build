<#
.Synopsis
	Tests task parameter splatting.
#>

task OK {
	Invoke-Build t1 -Result r {
		task t1 @{
			Jobs = {42}
		}
	}
	equals $r.Tasks.Count 1
	$t = $r.Tasks[0]
	equals $t.Name t1
	equals $t.Jobs.Count 1
	equals ($t.Jobs[0].ToString()) '42'
}

task MissingParam {
	try {
		Invoke-Build t1 {
			task t1 @{
				MissingParam = 1
			}
		}
	}
	catch {$err = $_}
	assert ("$err" -like "*Task 't1': * 'MissingParam'*")
}

task InvalidParam {
	try {
		Invoke-Build t1 {
			task t1 -If 1 @{}
		}
	}
	catch {$err = $_}
	equals "$err" "Task 't1': Invalid parameters."
}
