
<#
.Synopsis
	Tests the sample Tasks/Footer

.Example
	Invoke-Build * Footer.test.ps1
#>

# Define footers as task path, synopsis, and location, e.g. for Ctrl+Click in VSCode
Set-BuildFooter {
	param($Path)
	Write-Build Cyan "Task $Path : $(Get-BuildSynopsis $Task)"
	Write-Build DarkGray "$($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
}

# Synopsis: Run the sample.
task Sample {
	($r = Invoke-Build . ../Tasks/Footer/Footer.build.ps1)
	assert ($r -contains 'Task /Task1/Task2 : Some task description 2.')
	assert ($r -contains 'Task /Task1 : Some task description 1.')
}

# Synopsis: Test synopsis.
task Synopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r 'Test synopsis.'
}
