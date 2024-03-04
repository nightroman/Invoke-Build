
# Issue #152 (1). Also test the bootstrapping scenario.
# This used to fail on the second call of z.ps1.
task DoNotMakeScriptParametersNamed {
	# self-invoking build script
	Set-Content z.ps1 {
		param(
			[Parameter()]$Tasks
		)
		if (!$MyInvocation.ScriptName.EndsWith('Invoke-Build.ps1')) {
			return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
		}
		task Test {}
	}

	# invoke the script twice with the task name
	./z.ps1 Test
	./z.ps1 Test

	remove z.ps1
}

<#
	Issue #152 (2). Test positional parameters.
	Potential problem:
		- `Task` and `P1` both have position 0.
		- `File` and `P2` both have position 1.
	UPDATE: yes, it is a problem, see #217
	Fortunate current behaviour:
		PowerShell somehow does what we expect, shift positions of P1, P2, P3.
		This may change in the future, so we cover this by test.
	UPDATE: #217 now shifts positions but we keep the test anyway.
	Workarounds for the future:
		- Use `[CmdletBinding(PositionalBinding=$false)]` (PowerShell v3+) to enforce named parameters.
		- Set parameter positions explicitly starting with 2 (0, 1 are consumed by Task, File).
	UPDATE: The second is kind of used by #217 (shift +2)
#>
task PositionalParameters {
	Set-Content z.build.ps1 {
		param($P1, $P2, $P3)
		task Parameters {"$P1|$P2|$P3"}
	}

	# invoke the script with 5 positional parameters
	($r = Invoke-Build Parameters z.build.ps1 v1 v2 v3)
	assert ($r -contains 'v1|v2|v3')

	remove z.build.ps1
}
