
<#
.Synopsis
	Example build script with a conditional task.

.Description
	The Conditional task is typical for Debug|Release configuration scenarios.
	Such values as $Configuration are normally defined as parameters.
	In this example the task is invoked for Release configuration.

	The script also shows how to use script variables shared between tasks.

	The default task depends on the Conditional and tests whether it is called.

.Example
	# Debug configuration
	Invoke-Build . ConditionalTask.build.ps1 @{ Configuration = 'Debug' }

.Example
	# Release configuration
	Invoke-Build . ConditionalTask.build.ps1 @{ Configuration = 'Release' }

.Link
	Invoke-Build
	.build.ps1
#>

param
(
	$Configuration = 'Release'
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

task . Conditional, {
	switch($Configuration) {
		'Debug' {
			assert ($BeforeConditional -eq 'TODO')
			assert ($AfterConditional -eq 'TODO')
			assert ($Conditional -eq 'TODO')
			'Tested Debug.'
		}
		'Release' {
			assert ($BeforeConditional -eq 'DONE')
			assert ($AfterConditional -eq 'DONE')
			assert ($Conditional -eq 'DONE')
			'Tested Release.'
		}
		default {
			throw 'Invalid Configuration.'
		}
	}
}
