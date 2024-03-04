
task UnknownParameter {
	# parameter positions before IB
	$a1, $a2, $a3 = Get-ParameterPosition
	equals $a2 ($a1 + 1)
	equals $a3 ($a2 + 1)

	# call IB with an unknown parameter, this should fail
	# and the error should be friendly, not some cryptic
	try {
		throw Invoke-Build -bar
	}
	catch {
		equals "$_" "A parameter cannot be found that matches parameter name 'bar'."
	}

	# parameter positions after IB
	$b1, $b2, $b3 = Get-ParameterPosition
	if ($PSVersionTable.PSVersion.Major -eq 2) {
		equals $b1 $a1
		equals $b2 $a2
		equals $b3 $a3
	}
	else {
		# shifted +2 on every call
		equals $b1 ($a1 + 2)
		equals $b2 ($a2 + 2)
		equals $b3 ($a3 + 2)
	}
}

function Get-ParameterPosition {
	foreach($p in (Get-Command "$BuildRoot\217.build.ps1").Parameters.Values) {
		foreach ($a in $p.Attributes) {
			if ($a -is [System.Management.Automation.ParameterAttribute]) {
				$a.Position
			}
		}
	}
}
