
<#
.Synopsis
	Tests Invoke-TaskFromISE.ps1
#>

. .\Tools.ps1

# Mock $Context
function New-Context($Line) {
	$file = New-Object psobject
	$file | Add-Member -MemberType NoteProperty -Name Path -Value $TestFilePath

	$cursor = New-Object psobject
	$cursor | Add-Member -MemberType NoteProperty -Name Line -Value $Line

	$r = New-Object psobject
	$r | Add-Member -MemberType NoteProperty -Name CurrentFile -Value $file
	$r | Add-Member -MemberType NoteProperty -Name CursorPosition -Value $cursor
	Set-Variable -Name Context -Value $r -Scope 1
}

task test-file-null {
	New-Context
	$Context.CurrentFile = $null
	($r = try {Invoke-TaskFromVSCode.ps1} catch {$_})
	equals "$r" 'There is not a current file.'
}

task test-file-not-ps1 {
	New-Context
	$Context.CurrentFile.Path = 'test.txt'
	($r = try {Invoke-TaskFromVSCode.ps1} catch {$_})
	equals "$r" "The current file must be '*.ps1'."
}

task test-no-task {
	New-Context (Find-Line test-no-task)

	($r = Invoke-TaskFromVSCode.ps1)
	assert ($r -contains '//.//')
}

task test-t1-first-line {
	New-Context (Find-Line test-t1-first-line)
	($r = Invoke-TaskFromVSCode.ps1)
	assert ($r -contains '//t1//')
}

task test-t1-inner-line {
	New-Context (Find-Line test-t1-inner-line)
	($r = Invoke-TaskFromVSCode.ps1)
	assert ($r -contains '//t1//')
}

task test-t1-after-line {
	New-Context (Find-Line test-t1-after-line)
	($r = Invoke-TaskFromVSCode.ps1)
	assert ($r -contains '//t1//')
}

task test-fail {
	$line = Find-Line test-fail
	New-Context $line
	$r = ''
	try {Invoke-TaskFromVSCode.ps1} catch {$r = $_}
	equals "$r" Oops!
}
