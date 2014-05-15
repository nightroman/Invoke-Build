
<#
.Synopsis
	Tests Show-BuildTree.ps1.

.Example
	Invoke-Build * Tree.test.ps1
#>

function Get-NormalText($_) {
	$_.Trim() -replace '\s+', ' '
}

# Synopsis: Tree.
task Tree {
	$sample = Get-NormalText @'
. - Call tree tests.
    Tree (.) - Tree.
        {}
    CyclicReference (.) - Test cyclic reference.
        {}
    MissingReference (.) - Test missing reference.
        {}
    MissingTask (.) - Test missing task.
        {}
    {}
'@

	# no task is resolved to .
	($log = Show-BuildTree -File Tree.test.ps1 | Out-String)
	assert ($sample -eq (Get-NormalText $log))

	# * is the same fo this example
	($log = Show-BuildTree * Tree.test.ps1 | Out-String)
	assert ($sample -eq (Get-NormalText $log))
}

# Synopsis: Test cyclic reference.
task CyclicReference {
	[System.IO.File]::WriteAllText("$BuildRoot\z.build.ps1", {
		task task1 task2
		task task2 task1
		task . task1
	})
	Show-BuildTree . z.build.ps1
}

# Synopsis: Test missing reference.
task MissingReference {
	[System.IO.File]::WriteAllText("$BuildRoot\z.build.ps1", {
		task task1 missing, {}
		task . task1, {}
	})
	Show-BuildTree . z.build.ps1
}

# Synopsis: Test missing task.
task MissingTask {
	Show-BuildTree missing
}

<#
	Synopsis : Call tree tests.
	(also test getting synopsis)
#>
task . `
Tree,
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
