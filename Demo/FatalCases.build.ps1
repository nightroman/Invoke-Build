
<#
.Synopsis
	Tests fatal runtime errors.

.Description
	Fatal runtime errors are:
	* Errors in task script jobs (if task calls are not protected);
	* Errors in task If scripts (always);
	* Errors in task Inputs scripts (always);
	* Errors in task Outputs scripts (always);

	All problem cases are called using protected task jobs (@{Task=1} notation)
	in order to make sure that even protected calls cannot hide fatal errors.

.Link
	Invoke-Build
	.build.ps1
#>

# Import tasks Error1 and Error2 (dot-sourced because imported with data).
. .\SharedTasksData.tasks.ps1

# This task is prepared to survive on errors in Error1 and Error2. It would
# survive if it is called alone. But it fails because the error in Error2 is
# going to break the task Fails and the build anyway. So it all fails fast.
task AlmostSurvives @(
	# Tells to call the task Error1 and ignore its failure
	@{Error1=1},
	# Code invoked after the task Error1
	{
		"After Error1 -- this works"
	},
	# Tells to call the task Error2 and ignore its failure
	@{Error2=1},
	# This code is not going to be invoked
	{
		"After Error2 -- this is not called"
	}
)

# This task is prepared for errors in Error1, that is why build continues after
# the first error in the task AlmostSurvives. But this task is not prepared for
# errors in Error2, that is why the whole build fails. Note: it does not matter
# that the downstream task calls this as @{Fails=1}, the task Fails is not
# ready for errors in Error2 (otherwise it would call it as @{Error2=1}).
task Fails @(
	@{Error1=1},
	{},
	# This unprotected reference makes the build to fail.
	# IMPORTANT: This task Fails is not even get called.
	'Error2'
	{}
)

# This task calls the tests and fails due to issues in the Fails. Even
# protected call does not help: Fails is not prepared for errors in Error2.
task TestAlmostSurvives AlmostSurvives, @{Fails=1}

# Another case when a protected error is fatal. It is the case when the If
# script fails. The build fails as well because it is a programming issue.
task ScriptConditionFails -If { throw "If fails." } { throw }
task TestScriptConditionFails @{ScriptConditionFails=1}, { throw }

# Fatal case: the Inputs script fails.
task InputsFails -Inputs { throw 'Inputs fails.' } -Outputs {} { throw }
task TestInputsFails @{InputsFails=1}, { throw }

# Fatal case: the Outputs script fails.
task OutputsFails -Outputs { throw 'Outputs fails.' } -Inputs { '.build.ps1' } { throw }
task TestOutputsFails @{OutputsFails=1}, { throw }

# Fatal case: Inputs and Outputs (scriptblock) have different number of items
task InputsOutputsMismatch -Inputs { '.build.ps1' } -Outputs { } { throw }
task TestInputsOutputsMismatch @{InputsOutputsMismatch=1}, { throw }

# Fatal case: one of the Inputs items is missing.
task MissingInputsItems -Inputs { 'missing' } -Outputs {} { throw }
task TestMissingInputsItems @{MissingInputsItems=1}, { throw }
