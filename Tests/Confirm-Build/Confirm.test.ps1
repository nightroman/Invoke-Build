<#
.Synopsis
	Tests Confirm-Build using Tasks/Confirm demo and directly.
#>

Import-Module ..\Tools

# All Yes due to -Quiet
task Quiet {
	Invoke-Build MakeTea ../../Tasks/Confirm/Confirm.build.ps1 -Quiet -Result r
	equals $r.Tasks.Count 3
	equals $r.Tasks[0].Name BoilWater
	equals $r.Tasks[1].Name AddSugar
	equals $r.Tasks[2].Name MakeTea
}

# All Yes "interactive"
task AllYes {
	Set-Alias Confirm-Build Confirm-Build2
	function Confirm-Build2 {$true}

	Invoke-Build MakeTea ../../Tasks/Confirm/Confirm.build.ps1 -Result r
	equals $r.Tasks.Count 3
	equals $r.Tasks[0].Name BoilWater
	equals $r.Tasks[1].Name AddSugar
	equals $r.Tasks[2].Name MakeTea
}

# Answer No to 1st confirm.
task No {
	Set-Alias Confirm-Build Confirm-Build2
	function Confirm-Build2 {$false}

	Invoke-Build MakeTea ../../Tasks/Confirm/Confirm.build.ps1 -Result r
	equals $r.Tasks.Count 0
}

# Answer Yes to 1st (default), No to second (custom).
task YesNo {
	Set-Alias Confirm-Build Confirm-Build2
	function Confirm-Build2 {param($Query) !$Query}

	Invoke-Build MakeTea ../../Tasks/Confirm/Confirm.build.ps1 -Result r
	equals $r.Tasks.Count 2
	equals $r.Tasks[0].Name BoilWater
	equals $r.Tasks[1].Name MakeTea
}

# This test is not about Confirm-Build but this constant variable $Task was
# introduced due to Confirm-Build.
task setTaskVariableShouldFail {
	try {
		Invoke-Build * { $Task = 'cannot set this var' }
		throw
	}
	catch {
		$err = $_
	}
	equals "$err" 'Cannot overwrite variable Task because it is read-only or constant.'
}
