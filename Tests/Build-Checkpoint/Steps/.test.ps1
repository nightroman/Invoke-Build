
$Error1 = 'Omitted or script Checkpoint excludes Build, Auto, Resume, Preserve.'

task empty_checkpoint {
	try { throw Build-Checkpoint '' }
	catch { $_; assert ("$_".StartsWith("Cannot validate argument on parameter 'Checkpoint'. The argument is null or empty.")) }
}

task invalid_param_1 {
	try { throw Build-Checkpoint -Auto }
	catch { $_; equals "$_" $Error1 }
}

task invalid_param_2 {
	try { throw Build-Checkpoint z.ps1 -Auto }
	catch { $_; equals "$_" $Error1 }
}

task do_step1_fail_step_2 {
	remove Steps.build.ps1.clixml

	function Confirm-Build2 {if ($Task.Name -eq 'step2') {throw} else {$true}}
	Set-Alias Confirm-Build Confirm-Build2

	#! cover "omitted Checkpoint"
	try { Build-Checkpoint }
	catch {}
}

task resume_step_2 do_step1_fail_step_2, {
	requires -Path Steps.build.ps1.clixml

	function Confirm-Build2 {$true}
	Set-Alias Confirm-Build Confirm-Build2

	#! cover "script Checkpoint"
	Build-Checkpoint Steps.build.ps1

	assert (!(Test-Path Steps.build.ps1.clixml))
}
