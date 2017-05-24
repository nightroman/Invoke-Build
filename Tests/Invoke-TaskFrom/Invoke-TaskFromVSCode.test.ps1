
<#
.Synopsis
	Tests Invoke-TaskFromISE.ps1
#>

. ./Tools.ps1

# Fake $psEditor and $Context
function Use-Context {
	$file = New-Object psobject
	Add-Member -InputObject $file -MemberType NoteProperty -Name Path -Value $TestFilePath

	$cursor = New-Object psobject
	Add-Member -InputObject $cursor -MemberType NoteProperty -Name Line -Value 0

	$Context = New-Object psobject
	Add-Member -InputObject $Context -MemberType NoteProperty -Name CurrentFile -Value $file
	Add-Member -InputObject $Context -MemberType NoteProperty -Name CursorPosition -Value $cursor
	Set-Variable -Name Context -Value $Context -Scope 1

	$psEditor = New-Object psobject
	Add-Member -InputObject $psEditor -MemberType ScriptMethod -Name GetEditorContext -Value {$Context}
	Set-Variable -Name psEditor -Value $psEditor -Scope 1
}

task test-file-null {
	Use-Context
	$Context.CurrentFile = $null

	($r = try {Invoke-TaskFromVSCode.ps1} catch {$_})
	equals "$r" 'Cannot get the current file.'
}

task test-file-not-ps1 {
	Use-Context
	$Context.CurrentFile.Path = 'test.txt'

	($r = try {Invoke-TaskFromVSCode.ps1} catch {$_})
	equals "$r" "The current file must be '*.ps1'."
}

task test-no-task {
	Use-Context
	$Context.CursorPosition.Line = Find-Line test-no-task

	($r = Invoke-TaskFromVSCode.ps1)
	assert ($r -contains '//.//')
}

task test-t1-first-line {
	Use-Context
	$Context.CursorPosition.Line = Find-Line test-t1-first-line

	($r = Invoke-TaskFromVSCode.ps1)
	assert ($r -contains '//t1//')
}

task test-t1-inner-line {
	Use-Context
	$Context.CursorPosition.Line = Find-Line test-t1-inner-line

	($r = Invoke-TaskFromVSCode.ps1)
	assert ($r -contains '//t1//')
}

task test-t1-after-line {
	Use-Context
	$Context.CursorPosition.Line = Find-Line test-t1-after-line

	($r = Invoke-TaskFromVSCode.ps1)
	assert ($r -contains '//t1//')
}

task test-fail {
	Use-Context
	$Context.CursorPosition.Line = Find-Line test-fail

	$r = ''
	try {Invoke-TaskFromVSCode.ps1} catch {$r = $_}
	equals "$r" Oops!
}
