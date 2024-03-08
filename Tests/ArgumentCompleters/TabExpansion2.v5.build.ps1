
Enter-Build {
	Invoke-Build.ArgumentCompleters.ps1
}

function Invoke-Complete([Parameter()]$line_, $caret_=$line_.Length) {
	foreach($_ in (TabExpansion2 $line_ $caret_).CompletionMatches) {
		$_.CompletionText
	}
}

task CompleteTask {
	Set-Location ..\..
	($r = Invoke-Complete 'Invoke-Build Ma')
	equals $r markdown
}

task CompleteFile {
	Set-Location ..\..
	($r = Invoke-Complete 'Invoke-Build Test i')

	$folder1, $folder2, $files = $r
	equals $folder1 ib
	equals $folder2 InvokeBuild

	assert ($files.Count -ge 4)
	foreach($$ in $files) {
		assert ($$ -like 'i*.ps1')
	}
}
