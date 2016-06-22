
function Invoke-Complete([Parameter()]$line_, $caret_=$line_.Length) {
	foreach($_ in (TabExpansion2 $line_ $caret_).CompletionMatches) {
		$_.CompletionText
	}
}

task CompleteTask {
	Set-Location ..\..
	($r = Invoke-Complete 'Invoke-Build Ma')
	equals $r Markdown
}

task CompleteFile {
	Set-Location ..\..
	($r = Invoke-Complete 'Invoke-Build Test i')

	$folder, $files = $r
	equals $folder InvokeBuild

	assert ($files.Count -ge 6)
	foreach($$ in $files) {
		assert ($$ -like 'i*.ps1')
	}
}
