<#
.Synopsis
	Tests of Get-BuildProperty (property).

.Description
	This script should be called with no parameters.
#>

param(
	$Param1 = (property BuildFile),
	$Param2 = (property UserName missing),
	$Param3 = (property USER missing)
)

Import-Module .\Tools

equals $Param1 $BuildFile
equals (property BuildFile) $BuildFile

if (Test-Unix) {
	equals $Param3 $env:USER
	equals (property USER) $env:USER
}
else {
	equals $Param2 $env:USERNAME
	equals (property UserName) $env:USERNAME
}

$MissingProperty = property MissingProperty 42
equals $MissingProperty 42

# Null value is treated as missing, too
$MissingNullProperty = $null
$MissingNullProperty = property MissingProperty 42
equals $MissingNullProperty 42

# Error: missing property
task MissingProperty {
	($r = try {property _111126_181750} catch {$_})
	equals "$r" "Missing property '_111126_181750'."
	equals $r.InvocationInfo.ScriptName $BuildFile
	equals $r.FullyQualifiedErrorId Get-BuildProperty
	assert ($r.CategoryInfo.Category -eq 'ObjectNotFound')
}

# v3.3.4 (#60): Treat '' as not defined.
task EmptyStringAsNotDefined {
	$_170410_105214 = ''
	$env:_170410_105214 = ''
	equals (property _170410_105214 default-value) default-value

	$env:_170410_105214 = 'env-value'
	equals (property _170410_105214) env-value

	$_170410_105214 = 'var-value'
	equals (property _170410_105214) var-value
}

task BooleanEnvironmentVariable {
	$env:Value = $null
	Remove-Variable Value -ErrorAction 0

	$env:Value = ' 1 '; equals (property Value -Boolean) $true
	$env:Value = ' 0 '; equals (property Value -Boolean) $false
	$env:Value = ' TRUE '; equals (property Value -Boolean) $true
	$env:Value = ' FALSE '; equals (property Value -Boolean) $false

	$env:Value = ' '; equals (property Value -Boolean) $false
	$env:Value = ''; try {property Value -Boolean; throw} catch {equals "$_" "Missing property 'Value'."}
	$env:Value = $null; try {property Value -Boolean; throw} catch {equals "$_" "Missing property 'Value'."}

	$env:Value = $null
}

task BooleanSessionVariable {
	$env:Value = $null
	Remove-Variable Value -ErrorAction 0

	$Value = ' 1 '; equals (property Value -Boolean) $true
	$Value = ' 0 '; equals (property Value -Boolean) $false
	$Value = ' TRUE '; equals (property Value -Boolean) $true
	$Value = ' FALSE '; equals (property Value -Boolean) $false

	$Value = ' '; equals (property Value -Boolean) $false
	$Value = ''; try {property Value -Boolean; throw} catch {equals "$_" "Missing property 'Value'."}
	$Value = $null; try {property Value -Boolean; throw} catch {equals "$_" "Missing property 'Value'."}
}

task BooleanDefaultValue {
	$env:Value = $null
	Remove-Variable Value -ErrorAction 0

	equals (property Value ' 1 ' -Boolean) $true
	equals (property Value ' 0 ' -Boolean) $false
	equals (property Value ' TRUE ' -Boolean) $true
	equals (property Value ' FALSE ' -Boolean) $false

	equals (property Value '' -Boolean) $false
	equals (property Value ' ' -Boolean) $false
	try {property Value $null -Boolean; throw} catch {equals "$_" "Missing property 'Value'."}
}
