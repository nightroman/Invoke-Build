
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

#! ensure both folders and files
task CompleteFile {
	Set-Location ..
	($r = Invoke-Complete 'Invoke-Build Test a')

	$1, $2, $3, $4 = $r
	equals $1 ArgumentCompleters
	equals $2 Acknowledged.build.ps1
	equals $3 Alter.test.ps1
	equals $4 Assert.test.ps1
}
