
# Define headers as separator, task path, synopsis, and location, e.g. for Ctrl+Click in VSCode.
# Also change the default color to Green. If you need task start times, use `$Task.Started`.
Set-BuildHeader {
	param($Path)
	# separator line
	Write-Build Green ('=' * 79)
	# default header + synopsis
	Write-Build Green "Task $Path : $(Get-BuildSynopsis $Task)"
	# task location in a script
	Write-Build Green "At $($Task.InvocationInfo.ScriptName):$($Task.InvocationInfo.ScriptLineNumber)"
}

# Define footers similar to default but change the color to DarkGray.
Set-BuildFooter {
	param($Path)
	Write-Build DarkGray "Done $Path, $($Task.Elapsed)"
}

# Synopsis: Some task description 1.
task Task1 Task2, {
	'some output 1'
}

# Synopsis: Some task description 2.
task Task2 {
	'some output 2'
}
