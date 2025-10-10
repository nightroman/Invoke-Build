
<#
.Synopsis
	Tests Invoke-TaskFromVSCode.ps1
#>

. ./Tools.ps1

# Fake $psEditor and $Context
function Use-Context {
	$file = New-Object psobject
	Add-Member -InputObject $file -MemberType NoteProperty -Name Path -Value $TestFilePath
	Add-Member -InputObject $file -MemberType ScriptMethod -Name Save -Value {}

	$cursor = New-Object psobject
	Add-Member -InputObject $cursor -MemberType NoteProperty -Name Line -Value 0

	$Context = New-Object psobject
	Add-Member -InputObject $Context -MemberType NoteProperty -Name CurrentFile -Value $file
	Add-Member -InputObject $Context -MemberType NoteProperty -Name CursorPosition -Value $cursor
	Set-Variable -Name Context -Value $Context -Scope 1

	$psEditor = New-Object psobject
	Add-Member -InputObject $psEditor -MemberType ScriptMethod -Name GetEditorContext -Value {$Context}
	Add-Member -InputObject $psEditor -MemberType NoteProperty -Name EditorServicesVersion -Value ([version]'1.6.0')
	Set-Variable -Name psEditor -Value $psEditor -Scope 1
}

function __warning($Message) {
	Write-Host $Message
}

task test-file-null {
	Use-Context
	$Context.CurrentFile = $null

	Set-Alias Write-Warning __warning
	Invoke-TaskFromVSCode.ps1 -InformationVariable iv
	equals $iv[0].ToString() 'No current file.'
}

task test-file-not-ps1 {
	Use-Context
	$Context.CurrentFile.Path = 'test.txt'

	Set-Alias Write-Warning __warning
	Invoke-TaskFromVSCode.ps1 -InformationVariable iv
	equals $iv[0].ToString() 'No current .ps1 file.'
}

task test-no-task {
	Use-Context
	$Context.CursorPosition.Line = Find-Line test-no-task

	Set-Alias Write-Warning __warning
	Invoke-TaskFromVSCode.ps1 -InformationVariable iv
	equals $iv[0].ToString() 'No current task.'
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

# first redefined emits warning
task redefined-1 {
	Use-Context
	$Context.CursorPosition.Line = Find-Line redefined-1

	Set-Alias Write-Warning __warning
	($r = Invoke-TaskFromVSCode.ps1 -InformationVariable iv)
	assert ($r -contains 'Redefined task.')
	assert ($iv[0].ToString() -like 'Invoking redefined task at *\1.build.ps1:28')
}

# last redefined has no warning
task redefined-2 {
	Use-Context
	$Context.CursorPosition.Line = Find-Line redefined-2

	Set-Alias Write-Warning __warning
	($r = Invoke-TaskFromVSCode.ps1 -InformationVariable iv)
	assert ($r -contains 'Redefined task.')
	equals $iv.Count 0
}
