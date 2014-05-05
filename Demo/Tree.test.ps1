
<#
.Synopsis
	Tests Show-BuildTree.ps1.

.Example
	Invoke-Build * Tree.test.ps1
#>

# Tree.
task Tree {
	# no task is resolved to .
	($log = Show-BuildTree -File Tree.test.ps1 | Out-String)
	assert ($log -like '*.*    Tree (.)*    Comment (.)*')
	assert (!$log.Contains('#'))

	# * is the same fo this example
	($log2 = Show-BuildTree * Tree.test.ps1 | Out-String)
	assert ($log2 -eq $log)
}

# Comment.
task Comment {
	($log = Show-BuildTree -File Tree.test.ps1 -Comment | Out-String)

	# ensure comments are there
	($log = $log -replace '\r\n', '=')
	assert ($log -like '*=<#=Call tree tests.=#>=.=*')
	assert ($log -like '*=    # Tree.=    Tree (.)=        {}=*')
	assert ($log -like '*=    # Comment.=    Comment (.)=        {}=*')
}

task CyclicReference {
	[System.IO.File]::WriteAllText("$BuildRoot\z.build.ps1", {
		task task1 task2
		task task2 task1
		task . task1
	})
	Show-BuildTree . z.build.ps1
}

task MissingReference {
	[System.IO.File]::WriteAllText("$BuildRoot\z.build.ps1", {
		task task1 missing, {}
		task . task1, {}
	})
	Show-BuildTree . z.build.ps1
}

task MissingTask {
	Show-BuildTree missing
}

<#
Call tree tests.
#>
task . `
Tree,
Comment,
(job CyclicReference -Safe),
(job MissingReference -Safe),
(job MissingTask -Safe),
{
	$e = error CyclicReference
	assert ("$e" -like "Task 'task2': Cyclic reference to 'task1'.*At *z.build.ps1:3 *")

	$e = error MissingReference
	assert ("$e" -like "Task 'task1': Missing task 'missing'.*At *z.build.ps1:2 *")

	$e = error MissingTask
	assert ("$e" -like "*Missing task 'missing'.*")

	Remove-Item z.*
}
