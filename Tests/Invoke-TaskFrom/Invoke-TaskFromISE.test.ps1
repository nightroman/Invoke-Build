<#
.Synopsis
	Tests Invoke-TaskFromISE.ps1
#>

Import-Module ..\Tools
if (Test-Unix) {return task unix}

. .\Tools.ps1

# Mock $psISE
function New-Context($Line) {
	$editor = New-Object psobject
	$editor | Add-Member -MemberType NoteProperty -Name CaretLine -Value $Line
	$editor | Add-Member -MemberType NoteProperty -Name CaretColumn -Value 1
	$editor | Add-Member -MemberType ScriptMethod -Name SetCaretPosition -Value {
		param($Line, $Column)
		$this.CaretLine = $Line
		$this.CaretColumn = $Column
	}

	$file = New-Object psobject
	$file | Add-Member -MemberType NoteProperty -Name IsUntitled -Value $false
	$file | Add-Member -MemberType NoteProperty -Name IsSaved -Value $false
	$file | Add-Member -MemberType NoteProperty -Name FullPath -Value $TestFilePath
	$file | Add-Member -MemberType NoteProperty -Name Editor -Value $editor
	$file | Add-Member -MemberType NoteProperty -Name SaveCalls -Value 0
	$file | Add-Member -MemberType ScriptMethod -Name Save -Value {
		$this.IsSaved = $true
		++$this.SaveCalls
	}

	$r = New-Object psobject
	$r | Add-Member -MemberType NoteProperty -Name CurrentFile -Value $file
	$r | Add-Member -MemberType NoteProperty -Name Editor -Value $editor
	Set-Variable -Name psISE -Value $r -Scope 1
}

task test-file-null {
	New-Context
	$psISE.CurrentFile = $null
	($r = try {Invoke-TaskFromISE.ps1} catch {$_})
	equals "$r" 'There is not a current file.'
}

task test-file-not-ps1 {
	New-Context
	$psISE.CurrentFile.FullPath = 'test.txt'
	($r = try {Invoke-TaskFromISE.ps1} catch {$_})
	equals "$r" "The current file must be '*.ps1'."
}

task test-file-untitled {
	New-Context
	$psISE.CurrentFile.IsUntitled = $true
	($r = try {Invoke-TaskFromISE.ps1} catch {$_})
	equals "$r" 'Cannot invoke for Untitled files, please save the file.'
}

task test-no-task-with-save {
	New-Context (Find-Line test-no-task)
	equals $psISE.CurrentFile.IsSaved $false

	($r = Invoke-TaskFromISE.ps1)
	assert ($r -contains '//.//')

	equals $psISE.CurrentFile.IsSaved $true
	equals $psISE.CurrentFile.SaveCalls 1
}

task test-no-task-without-save {
	New-Context (Find-Line test-no-task)
	$psISE.CurrentFile.IsSaved = $true

	($r = Invoke-TaskFromISE.ps1)
	assert ($r -contains '//.//')

	equals $psISE.CurrentFile.IsSaved $true
	equals $psISE.CurrentFile.SaveCalls 0
}

task test-t1-first-line {
	New-Context (Find-Line test-t1-first-line)
	($r = Invoke-TaskFromISE.ps1)
	assert ($r -contains '//t1//')
}

task test-t1-inner-line {
	New-Context (Find-Line test-t1-inner-line)
	($r = Invoke-TaskFromISE.ps1)
	assert ($r -contains '//t1//')
}

task test-t1-after-line {
	New-Context (Find-Line test-t1-after-line)
	($r = Invoke-TaskFromISE.ps1)
	assert ($r -contains '//t1//')
}

task test-fail {
	$line = Find-Line test-fail
	New-Context $line
	$r = ''
	try {Invoke-TaskFromISE.ps1} catch {$r = $_}
	equals "$r" Oops!
	equals $psISE.Editor.CaretLine ($line + 1)
	#! v2: 18. Enough to test in v5+.
	if ($PSVersionTable.PSVersion.Major -ge 5) {
		equals $psISE.Editor.CaretColumn 13
	}
}
