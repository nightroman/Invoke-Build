
if ($PSVersionTable.PSVersion.Major -lt 7) {return task not_v7}

task see_rendering {
	Set-Alias msbuild (Resolve-MSBuild)
	$r = exec { msbuild project.proj }
	$r = $r.Where({!$_.Contains('Build started')})
	$r
	assert (!($r | Out-String).Contains('[0m'))
}
