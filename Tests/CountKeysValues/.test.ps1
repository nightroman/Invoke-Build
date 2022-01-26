# Test script for fixed IDictionary Count, Keys, Values issues.
# Fixed but not tested here tools:
# - Invoke-TaskFromISE.ps1
# - Invoke-TaskFromVSCode.ps1
# - Invoke-Build.ArgumentCompleters.ps1

. ..\Shared.ps1
$Version = $PSVersionTable.PSVersion.Major

# used to fail
task parameters {
	($r = Invoke-Build -Count c -Keys k -Values v | Out-String)
	assert ($r -like '*param(c, k, v)*')
}

# used to show just `values`
task question {
	($r = Invoke-Build ? | Format-Table -AutoSize | Out-String)
	assert ($r -like '*count  {}*')
	assert ($r -like '*keys   {}*')
	assert ($r -like '*values {}*')
	assert ($r -like '*.      {count, keys, values, {}}*')
}

# used to fail
task Show-BuildTree {
	($r = Show-BuildTree.ps1 * | Out-String)
	assert ($r -like '*    count*')
	assert ($r -like '*    keys*')
	assert ($r -like '*    values*')
}

# used to out funny parameters and environment
task WhatIf -If ($Version -ne 2) {
	($r = Invoke-Build -WhatIf | Out-String)
	$r = $r -replace ' '
	$r = $r -replace '\r?\n', '|'
	$r = Remove-Ansi $r
	assert ($r.Contains('|Parameters:|[Object]Count|[Object]Keys|[Object]Values|Environment:|Count,Keys,Values|'))
}

# used to fail
task Build-Checkpoint {
	Build-Checkpoint -Checkpoint z.clixml
}

# used to build all except `values` instead of just `.`
task Build-JustTask {
	($r = Build-JustTask.ps1 . | Out-String)
	assert ($r -like '*Task /./count skipped.*')
	assert ($r -like '*Task /./keys skipped.*')
	assert ($r -like '*Task /./values skipped.*')
}

# used to fail
task Build-Parallel {
	($r = Build-Parallel.ps1 @{Count='c'; Keys='k'; Values='v'} | Out-String)
	assert ($r -like '*param(c, k, v)*')
	assert ($r -like '*Tasks: 4 tasks, 0 errors, 0 warnings*')
}

# used to show just `values`
task Show-BuildDgml {
	Show-BuildDgml.ps1 -NoShow -Output z.dgml
	$r = Get-Content z.dgml | Out-String
	assert ($r.Contains('<Node Id="count" Category="Script" />'))
	assert ($r.Contains('<Node Id="keys" Category="Script" />'))
	assert ($r.Contains('<Node Id="values" Category="Script" />'))
	assert ($r.Contains('<Node Id="." Category="Script" />'))
	remove z.dgml
}

# used to show just `values`
task Show-BuildGraph -If (!$IsUnix -and !$env:GITHUB_ACTION) {
	Show-BuildGraph.ps1 -NoShow -Output z.dot
	$r = Get-Content z.dot | Out-String
	assert ($r.Contains('"." -> count'))
	assert ($r.Contains('"." -> keys'))
	assert ($r.Contains('"." -> values'))
	remove z.dot
}

# used to generate just `values`
task New-VSCodeTask -If ($Version -ne 2) {
	New-VSCodeTask.ps1
	$r = (Get-Content .vscode/tasks.json | Out-String) -replace '\s+', ' '
	assert ($r.Contains('"label": "count"'))
	assert ($r.Contains('"label": "keys"'))
	assert ($r.Contains('"label": "values"'))
	assert ($r.Contains('"label": "."'))
	remove .vscode
}
