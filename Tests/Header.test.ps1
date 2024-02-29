<#
.Synopsis
	Tests the sample Tasks/Header
#>

Import-Module .\Tools

# Define headers as task path, synopsis, and location, e.g. for Ctrl+Click in VSCode
Set-BuildHeader {
    param($Path)
    Write-Build Cyan "Task $Path : $(Get-BuildSynopsis $Task)"
	Write-Build DarkGray "$($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
}

# Synopsis: Run the sample and test its output.
task Sample {
	# invoke all, including child
	($r = Invoke-Build * ../Tasks/Header/1.build.ps1)

	# test custom headers (added synopsis)
	$r = Remove-Ansi $r
	assert ($r -contains 'Task /Task1/Task2 : Some task description 2.')
	assert ($r -contains 'Task /Task1 : Some task description 1.')

	# test custom footers (added comma)
	assert ($r -like 'Done /Task1/Task2,*')
	assert ($r -like 'Done /Task1,*')

	# child build inherits headers and footers
	assert ($r -contains 'Task /ChildTask1 : Child task description 1.')
	assert ($r -like 'Done /ChildTask1,*')
}

# Synopsis: Test synopsis.
task Synopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r 'Test synopsis.'
}
