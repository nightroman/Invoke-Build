
<#
.Synopsis
	Example build script with a conditional task.

.Description
	The Conditional task is typical for Debug|Release configuration scenarios.
	In this example the task is designed to be done for Release configuration.
	It is also typical that $Configuration is defined used as a parameter.

	The script also shows how to use script variables shared between tasks.

	The default task depends on the Conditional and tests whether it is called.

.Example
	# Debug configuration
	Invoke-Build default ConditionalTask.build.ps1 @{ Configuration = 'Debug' }

.Example
	# Release configuration
	Invoke-Build default ConditionalTask.build.ps1 @{ Configuration = 'Release' }

.Link
	.build.ps1
#>

param
(
	$Configuration
)

$BeforeConditional = 'TODO'
$AfterConditional = 'TODO'
$Conditional = 'TODO'

task BeforeConditional {
	$script:BeforeConditional = 'DONE'
}

task AfterConditional {
	$script:AfterConditional = 'DONE'
}

task Conditional -If ($Configuration -eq 'Release') BeforeConditional, { $script:Conditional = 'DONE' }, AfterConditional

task default Conditional, {
	switch($Configuration) {
		'Debug' {
			if ($BeforeConditional -ne 'TODO') { throw }
			if ($AfterConditional -ne 'TODO') { throw }
			if ($Conditional -ne 'TODO') { throw }
			Out-Color Green 'Tested Debug.'
		}
		'Release' {
			if ($BeforeConditional -ne 'DONE') { throw }
			if ($AfterConditional -ne 'DONE') { throw }
			if ($Conditional -ne 'DONE') { throw }
			Out-Color Green 'Tested Release.'
		}
		default {
			throw 'Invalid Configuration.'
		}
	}
}
