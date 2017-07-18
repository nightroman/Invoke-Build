
<#
.Synopsis
	Tests custom ask-tasks, see Tasks/Ask
#>

. ../Shared.ps1

# Ask-tasks with `If`
task Conditions {
	# answer Yes
	. Set-Mock Test-AskTask {$true}
	Invoke-Build IfValue0, IfValue1, IfScript0, IfScript1 -Result r
	equals $r.Tasks.Count 2
	equals $r.Tasks[0].Name IfValue1
	equals $r.Tasks[1].Name IfScript1

	# answer No
	. Set-Mock Test-AskTask {$false}
	Invoke-Build IfValue0, IfValue1, IfScript0, IfScript1 -Result r
	equals $r.Tasks.Count 0
}

# Test references, also cover the example script
task References {
	# answer Yes
	. Set-Mock Test-AskTask {$true}
	Invoke-Build MakeTea ../../Tasks/Ask/Ask.build.ps1 -Result r
	equals $r.Tasks.Count 3
	equals $r.Tasks[0].Name BoilWater
	equals $r.Tasks[1].Name AddSugar
	equals $r.Tasks[2].Name MakeTea

	# answer No
	. Set-Mock Test-AskTask {$false}
	Invoke-Build MakeTea ../../Tasks/Ask/Ask.build.ps1 -Result r
	equals $r.Tasks.Count 0
}
