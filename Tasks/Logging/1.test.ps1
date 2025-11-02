<#
.Synopsis
	Tests several logging methods with `Logging.build.ps1`.
	run: Invoke-Build **
	see: z.content.log, z.file.log, z.tee.log, z.transcript.log
#>

if ($env:IB_TESTING) {return task skip}

task content {
	Invoke-Build * *>&1 | Set-Content z.content.log
}

task file {
	Invoke-Build * *>&1 | Out-File z.file.log -Encoding utf8 -Width 9999
}

task tee {
	Invoke-Build * *>&1 | Tee-Object z.tee.log
}

task transcript {
	Invoke-Build * -UseTranscript
}
