<#
.Synopsis
	Get-BuildVersion tests.

.Description
	File version strings are like v5.13.0, lower case 'v'.
	Tests deliberately use -Regex with upper case 'V'.
#>

task pattern {
	# Get-BuildVersion uses `-match` ~ ignore case
	$Script:Version = Get-BuildVersion ..\Release-Notes.md '##\s+(V\d+\.\d+\.\d+)'
	assert ($Version -match '^v\d+\.\d+\.\d+$')
}

task regex1 pattern, {
	# use Regex instance with inline ignore case option `(?i)`
	$r = Get-BuildVersion ..\Release-Notes.md ([regex]'(?i)##\s+(V\d+\.\d+\.\d+)')
	equals $r $Version
}

task regex2 pattern, {
	# use Regex instance with explicit ignore case option
	$r = Get-BuildVersion ..\Release-Notes.md ([regex]::new('##\s+(V\d+\.\d+\.\d+)', 'IgnoreCase'))
	equals $r $Version
}

task bad_Path {
	try {
		# -Regex does not matter, it fails due to missing file
		<##> Get-BuildVersion missing.md *
		throw
	}
	catch {
		assert ("$_" -like "*Could not find file '*missing.md'.")
		assert $_.InvocationInfo.PositionMessage.Contains('<##>')
	}
}

task bad_Regex {
	try {
		# use Regex instance case sensitive -> 'V' does not match 'v'
		<##> Get-BuildVersion ..\Release-Notes.md ([regex]'##\s+(V\d+\.\d+\.\d+)')
		throw
	}
	catch {
		assert ("$_" -like "*Cannot find version in '*Release-Notes.md'.")
		assert $_.InvocationInfo.PositionMessage.Contains('<##>')
	}
}
