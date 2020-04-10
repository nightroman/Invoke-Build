<#
.Synopsis
	Used by Invoke-TaskFromISE.test.ps1 and Invoke-TaskFromVSCode.test.ps1
#>

$TestFilePath = Join-Path $BuildRoot InvokeFrom.build.ps1
$Content = Get-Content $TestFilePath

function Find-Line($Text) {
	for($$ = 0; $$ -lt $Content.Count; ++$$) {
		if ($Content[$$].Contains($Text)) {
			return $$ + 1
		}
	}
	Write-Error "'$Text' is not found"
}
