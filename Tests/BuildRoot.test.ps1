<#
.Synopsis
	Tests the custom $BuildRoot, see https://github.com/nightroman/Invoke-Build/issues/95

.Description
	All tests except Parameter define builds as script blocks. Unlike build
	scripts, blocks do not have own natural build roots because they are not
	files in some directories. Their conventional build roots come from the
	calling scripts. This is not always what the builds require, so use of
	custom build roots is especially important for script block builds.
#>

<#
	Features:
	- Specify the custom $BuildRoot as the parameter.
	- Provide the default value based on the original $BuildRoot.
	- Run with the default custom root and passed as the parameter.
	- Custom paths are normalized, i.e. // and .. are not in the result.
#>
task Parameter {
	Set-Content z.ps1 {
		param(
			$BuildRoot = "$BuildRoot//.."
		)
		task root {
			($ref.Value = $BuildRoot)
		}
	}

	$ref = @{}
	Invoke-Build root z.ps1
	equals $ref.Value (Split-Path $BuildRoot)

	$ref = @{}
	Invoke-Build root z.ps1 -BuildRoot ..//..
	equals $ref.Value (Split-Path (Split-Path $BuildRoot))

	Remove-Item z.ps1
}

task Relative {
	$file = {
		# change to another location
		Set-Location ..
		# tell to use it just as '.'
		$BuildRoot = '.'
		# tasks use it as the full path
		task root {
			($ref.Value = $BuildRoot)
		}
	}
	$ref = @{}
	Invoke-Build root $file
	equals $ref.Value (Split-Path $BuildRoot)
}

task Invalid {
	$file = {
		$BuildRoot = ":"
		task root
	}
	($r = try {Invoke-Build root $file} catch {$_})

	$e = $r[-1]
	assert ($e.CategoryInfo.Category -eq 'ObjectNotFound')
	equals $e.FullyQualifiedErrorId Invoke-Build.ps1
	equals $e.InvocationInfo.ScriptName $BuildFile
	assert ("$e" -match 'Missing build root ''.*?[\\/]:''.')
}

task Constant1 {
	$file = {
		task root {
			$script:BuildRoot = 'z'
		}
	}
	($r = try {Invoke-Build root $file} catch {$_})
	equals $r[-1].FullyQualifiedErrorId VariableNotWritable
}

task Constant2 {
	$file = {
		Enter-Build {$BuildRoot = 'z'}
		task root
	}
	($r = try {Invoke-Build root $file} catch {$_})
	equals $r[-1].FullyQualifiedErrorId VariableNotWritable
}
