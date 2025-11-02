<#
.Synopsis
	Build script for testing several logging methods.
	Use `1.test.ps1` to run them and see `z.*.log`.
#>

param(
	[switch]$UseTranscript,
	[switch]$TryBadObject
)

Enter-Build {
	if ($UseTranscript) { Start-Transcript z.transcript.log }
}

Exit-Build {
	if ($UseTranscript) { Stop-Transcript }
}

# Use *>&1 to log all these writes, not just text.
task ps-output {
	'Test of Plain-Text'
	print Green 'Test of Green-Text'
	Write-Output 'Test of Write-Output'

	Write-Host 'Test of Write-Host'

	$DebugPreference = 'continue'
	Write-Debug 'Test of Write-Debug'

	$VerbosePreference = 'continue'
	Write-Verbose 'Test of Write-Verbose'

	$WarningPreference = 'continue'
	Write-Warning 'Test of Write-Warning'

	$ErrorActionPreference = 'continue'
	Write-Error 'Test of Write-Error'
}

# Skipped by default as the troublemaker.
# Try:
# - run: Invoke-Build * -UseTranscript -TryBadObject
# - see: z.transcript.log -- nothing after `Task /object-output-1`
task object-output-1 -If $TryBadObject {
	[pscustomobject]@{
		memo = (1..40).ForEach{"word $_"} -join ' '
		name = 'John Doe'
	}
}

# Use Out-String for writing objects.
task object-output-2 {
	[pscustomobject]@{
		memo = (1..40).ForEach{"word $_"} -join ' '
		name = 'John Doe'
	} | Format-List | Out-String
}

# Native output is missing on transcribing.
task native-output-1 {
	cmd /c dir *.ps1
}

# Native output is included on transcribing.
task native-output-2 {
	(cmd /c dir *.ps1)
}
