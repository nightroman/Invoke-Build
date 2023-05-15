if ($PSVersionTable.PSVersion.Major -lt 5) {return task v5}

# info is not shown by default
task default {
	($r = Invoke-PowerShell -Command Invoke-Build | Out-String)
	assert (!$r.Contains('MyInformation'))
}

# info is shown with -InformationAction
task with_action {
	($r = Invoke-PowerShell -Command 'Invoke-Build -InformationAction Continue' | Out-String)
	assert ($r.Contains('MyInformation'))
}

# info is not shown but collected with -InformationVariable
task with_variable {
	($r = Invoke-PowerShell -Command 'Invoke-Build -InformationVariable InformationVariable' | Out-String)
	assert (!$r.Contains('MyInformation'))

	Invoke-Build -InformationVariable InformationVariable
	equals $InformationVariable.Count 1
	equals $InformationVariable[0].MessageData MyInformation
}

# info is shown and collected with -InformationAction and -InformationVariable
task with_action_and_variable {
	($r = Invoke-PowerShell -Command 'Invoke-Build -InformationAction Continue -InformationVariable InformationVariable' | Out-String)
	assert ($r.Contains('MyInformation'))

	Invoke-Build -InformationAction Continue -InformationVariable InformationVariable
	equals $InformationVariable.Count 1
	equals $InformationVariable[0].MessageData MyInformation
}
