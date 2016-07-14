
<#
.Synopsis
	Tests Show-BuildTree.ps1.

.Example
	Invoke-Build * Tree.test.ps1
#>

function Get-NormalText($_) {
	$_.Trim() -replace '\s+', ' '
}

function Assert-Same($A, $B) {
	$1 = Get-NormalText ($A -join ' ')
	$2 = Get-NormalText ($B -join ' ')
	try {equals $1 $2} catch {Write-Error $_}
}

# Synopsis: Simple tree.
task SimpleTree {
	Set-Content z.ps1 {
		<#
			Synopsis: t1
			blah blah
		#>
		task t1 {}
		# Synopsis: t2
		task t2 {}
		# Synopsis: dot
		task . t1, t2, {}
		task root {}
	}

	# with omitted -Task resolved to .
	($r = Show-BuildTree -File z.ps1)
	Assert-Same $r @'
. # dot
    t1 # t1
        {}
    t2 # t2
        {}
    {}
'@

	Remove-Item z.ps1
}

# Synopsis: Tree with upstream tasks.
task UpstreamTree {
	Set-Content z.ps1 {
		# Synopsis: t1
		task t1 {}
		# Synopsis: t2
		task t2 {}
		# Synopsis: dot
		task . t1, t2, {}
		task root {}
	}

	# with -Task * resolved gets two trees
	($r = Show-BuildTree * z.ps1 -Upstream)
	Assert-Same $r @'
. # dot
    t1 (.) # t1
        {}
    t2 (.) # t2
        {}
    {}

root
    {}
'@

	Remove-Item z.ps1
}

# Synopsis: Test cyclic reference.
task CyclicReference {
	Set-Content z.ps1 {
		task task1 task2
		task task2 task1
		task . task1
	}

	($r = try {Show-BuildTree . z.ps1} catch {$_})
	assert ("$r" -like "Task 'task2': Cyclic reference to 'task1'.*At *z.ps1:3 *")

	Remove-Item z.ps1
}

# Synopsis: Test missing reference.
task MissingReference {
	Set-Content z.ps1 {
		task task1 missing, {}
		task . task1, {}
	}

	($r = try {Show-BuildTree . z.ps1} catch {$_})
	assert ("$r" -like "Task 'task1': Missing task 'missing'.*At *z.ps1:2 *")

	Remove-Item z.ps1
}

# Synopsis: Test missing task.
task MissingTask {
	($r = try {Show-BuildTree missing} catch {$_})
	equals "$r" "Missing task 'missing'."
}

# Synopsis: Test -Parameters.
task TreeParameters {
	Set-Content z.ps1 {
		param($p1)
		if ($p1) {
			task p1
		}
		else {
			task default
		}
	}

	($r = Show-BuildTree -File z.ps1)
	equals $r[1] default

	($r = Show-BuildTree -File z.ps1 -Parameters @{p1=1})
	equals $r[1] p1

	Remove-Item z.ps1
}
