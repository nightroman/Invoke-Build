
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
			assert ($BeforeConditional -eq 'TODO')
			assert ($AfterConditional -eq 'TODO')
			assert ($Conditional -eq 'TODO')
			Out-Color Green 'Tested Debug.'
		}
		'Release' {
			assert ($BeforeConditional -eq 'DONE')
			assert ($AfterConditional -eq 'DONE')
			assert ($Conditional -eq 'DONE')
			Out-Color Green 'Tested Release.'
		}
		default {
			throw 'Invalid Configuration.'
		}
	}
}
