
<#
.Synopsis
	Tests the sample Tasks/Header

.Example
	Invoke-Build * Header.test.ps1
#>

# Define headers as task path, synopsis, and location, e.g. for Ctrl+Click in VSCode
Set-BuildHeader {
    param($Path)
    Write-Build Cyan "Task $Path : $(Get-BuildSynopsis $Task)"
	Write-Build DarkGray "$($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
}

# Synopsis: Run the sample and test its output.
task Sample {
	($r = Invoke-Build . ../Tasks/Header/Header.build.ps1)
	# test custom headers (added synopsis)
	assert ($r -contains 'Task /Task1/Task2 : Some task description 2.')
	assert ($r -contains 'Task /Task1 : Some task description 1.')
	# test custom footers (added comma)
	assert ($r -like 'Done /Task1/Task2,*')
	assert ($r -like 'Done /Task1,*')
}

# Synopsis: Test synopsis.
task Synopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r 'Test synopsis.'
}
