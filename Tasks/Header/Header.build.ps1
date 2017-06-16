
# Define headers as separator, task path, synopsis, and location, e.g. for Ctrl+Click in VSCode
Set-BuildHeader {
	param($Path)
	'=' * 79
	Write-Build Cyan "Task $Path : $(Get-BuildSynopsis $Task)"
	Write-Build DarkGray "$($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
}

# Synopsis: Some task description 1.
task Task1 Task2, {
	'some output 1'
}

# Synopsis: Some task description 2.
task Task2 {
	'some output 2'
}
