
# Define footers as separator, task path, synopsis, and location, e.g. for Ctrl+Click in VSCode.
# If you need task start times, use `$Task.Started`.
Set-BuildFooter {
	param($Path)
	# separator line
	'=' * 79
	# default header + synopsis
	Write-Build Cyan "Task $Path : $(Get-BuildSynopsis $Task)"
	# task location in a script
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
