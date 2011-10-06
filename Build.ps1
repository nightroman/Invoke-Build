
<#
.Synopsis
	Invoke-Build wrapper for command prompt.

.Description
	This script is for interactive use. Build scripts should use Invoke-Build.

	If the parameter File is not specified and there is no *.build.ps1 files in
	the current location then $env:InvokeBuildGetFile is called if it exists.
	It gets either nothing or the file path based on the current location.

	If File is still not defined then this script searches for *.build.ps1
	candidates in the parent directory tree.

	Parameters are almost the same as Invoke-Build parameters but
	* The switch Summary is added
	* The Result is not available

.Parameter Task
		PS> help Invoke-Build -Parameter Task
.Parameter File
		PS> help Invoke-Build -Parameter File
.Parameter Parameters
		PS> help Invoke-Build -Parameter Parameters
.Parameter WhatIf
		PS> help Invoke-Build -Parameter WhatIf
.Parameter Summary
		Tells to output task summary information after the build.
#>

param
(
	[Parameter(Position = 0)]
	[string[]]$Task
	,
	[Parameter(Position = 1)]
	[string]$File
	,
	[Parameter(Position = 2)]
	[hashtable]$Parameters
	,
	[Parameter()]
	[switch]$WhatIf
	,
	[Parameter()]
	[switch]$Summary
)

# resolve the file and root
if (!$File -and !(Test-Path '*.build.ps1')) {

	# call the script $env:InvokeBuildGetFile
	if ([System.IO.File]::Exists($env:InvokeBuildGetFile)) {
		$File = & $env:InvokeBuildGetFile
	}

	# continue search in the parent tree
	if (!$File) {
		$private:location = Get-Location
		for(;; $private:location = Split-Path $private:location) {
			if (!$private:location) {
				throw "Cannot find *.build.ps1 in the parent tree."
			}
			$private:candidate = @(Get-ChildItem -LiteralPath $private:location -Filter '*.build.ps1')
			if ($private:candidate.Count -eq 1) {
				$File = $private:candidate[0].FullName
				break
			}
			elseif ($private:candidate.Count -gt 1) {
				$private:candidate = $private:candidate -match '\\\.build\.ps1$'
				if (!$private:candidate) {
					throw "Found more than one '*.build.ps1' and none of them is '.build.ps1'."
				}
				$File = $private:candidate.FullName
			}
		}
	}
}

# hide variables
$private:_Task = $Task
$private:_File = $File
$private:_Parameters = $Parameters
$private:_Summary = $Summary
Remove-Variable Task, File, Parameters, Summary

# build, keep the results
try {
	Invoke-Build.ps1 -Task:$_Task -File:$_File -Parameters:$_Parameters -WhatIf:$WhatIf -Result Result
}
finally {
	# show summary
	if ($_Summary) {
		foreach($_ in $Result.AllTasks) {
			Write-Host ('{0,-16} {1} @ {2}' -f $_.Elapsed, $_.Name, $_.Info.ScriptName)
			if ($_.Error) {
				Write-Host -ForegroundColor Red ($_.Error | Out-String)
			}
		}
	}
}
