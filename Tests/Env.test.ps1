<#
.Synopsis
	Tests `Use-BuildEnv`.
#>

task basic {
	$env:TEST_VAR1 = 'old'
	$env:TEST_VAR2 = 'old'
	$env:TEST_VAR3 = $null

	$v1, $v3 = Use-BuildEnv @{TEST_VAR1 = 'new'; TEST_VAR2 = $null; TEST_VAR3 = 'new' } {
		equals $env:TEST_VAR1 new
		equals $env:TEST_VAR2 $null
		equals $env:TEST_VAR3 new
		$env:TEST_VAR1
		$env:TEST_VAR3
	}

	equals $v1 new
	equals $v3 new

	equals $env:TEST_VAR1 old
	equals $env:TEST_VAR2 old
	equals $env:TEST_VAR3 $null
}

task error {
	$env:TEST_VAR1 = 'old'

	$err = try {
		Use-BuildEnv @{TEST_VAR1 = 'new' } {
			equals $env:TEST_VAR1 new
			throw 'oops'
		}
	}
	catch {
		$_
	}

	equals "$err" oops
	equals $env:TEST_VAR1 old
}
