<#
.Synopsis
	Tests of Test-BuildAsset (requires).
#>

task ImportSample {
	($r = Invoke-Build . ../Tasks/Import/.build.ps1)
	assert ($r -contains 'MyVar1 = var1')
	assert ($r -contains 'MyEnv1 = env1')
	assert ($r -contains 'MyProp1 = prop1')
	assert ($r -contains 'MyProp2 = prop2')
	assert ($r -match 'MyPath Length = \d+')
	assert ($r -contains '@Invoke-MyModuleStuff param1')
	assert ($r -contains 'MyExtraStuff = stuff1')
}

task Variable {
	($r = try {requires miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$miss1 = $null
	($r = try {requires miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$miss1 = ''
	($r = try {requires miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$miss1 = 0
	requires miss1
}

task Environment {
	($r = try {requires -Environment miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$env:miss1 = $null
	($r = try {requires -Environment miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$env:miss1 = ''
	($r = try {requires -Environment miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$env:miss1 = 0
	requires -Environment miss1

	$env:miss1 = $null
}

task Path {
	($r = try {<##> requires -Path miss1} catch {$_})
	equals "$r" "Missing path 'miss1'."
	assert $r.InvocationInfo.PositionMessage.Contains('<##>')

	($r = try {<##> requires -Path $BuildRoot, miss1} catch {$_})
	equals "$r" "Missing path 'miss1'."
	assert $r.InvocationInfo.PositionMessage.Contains('<##>')
}

task PropertyVariable {
	($r = try {requires -Property miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$miss1 = $null
	($r = try {requires -Property miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$miss1 = ''
	($r = try {requires -Property miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$miss1 = 0
	requires -Property miss1
}

task PropertyEnvironment {
	($r = try {requires -Property miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$env:miss1 = $null
	($r = try {requires -Property miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$env:miss1 = ''
	($r = try {requires -Property miss1} catch {$_})
	equals $r.FullyQualifiedErrorId Test-BuildAsset

	$env:miss1 = 0
	requires -Property miss1

	$env:miss1 = $null
}
