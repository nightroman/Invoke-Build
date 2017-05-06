
<#
.Synopsis
	Tests custom ask-tasks, see Tasks/Ask
#>

# Fakes
function Test-Yes {$true}
function Test-No {$false}

# Ask-tasks with `If`
task Conditions {
	# answer Yes
	Set-Alias Test-AskTask Test-Yes
	Invoke-Build IfValue0, IfValue1, IfScript0, IfScript1 -Result r
	equals $r.Tasks.Count 2
	equals $r.Tasks[0].Name IfValue1
	equals $r.Tasks[1].Name IfScript1

	# answer No
	Set-Alias Test-AskTask Test-No
	Invoke-Build IfValue0, IfValue1, IfScript0, IfScript1 -Result r
	equals $r.Tasks.Count 0
}

# Test references, also cover the example script
task References {
	# answer Yes
	Set-Alias Test-AskTask Test-Yes
	Invoke-Build MakeTea ../../Tasks/Ask/Ask.build.ps1 -Result r
	equals $r.Tasks.Count 3
	equals $r.Tasks[0].Name BoilWater
	equals $r.Tasks[1].Name AddSugar
	equals $r.Tasks[2].Name MakeTea

	# answer No
	Set-Alias Test-AskTask Test-No
	Invoke-Build MakeTea ../../Tasks/Ask/Ask.build.ps1 -Result r
	equals $r.Tasks.Count 0
}
