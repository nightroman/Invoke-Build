
<#
.Synopsis
	Example of the custom file-task.

.Description
	This script is a demo of incremental tasks and custom file-tasks.
	See "File.tasks.ps1" for the details of "file".

	A file-task is slightly easier to compose than similar "task". It is not a
	big deal but if incremental tasks are used often then "file" may be useful.

.Example
	Invoke-Build * File.build.ps1

	On the first run all tasks work and create "Task*.log" files. On next runs
	tasks are either skipped or invoked as soon as temp files are updated.
#>

# Import file-task.
. .\File.tasks.ps1

# Gets *.tmp files from the temp directory. Used in two tasks.
$GetTmpFiles = { [System.IO.Directory]::GetFiles($env:TEMP, '*.tmp') }

# Synopsis: Log temp files using "task".
task Task1 -Inputs $GetTmpFiles -Outputs Task1.log {
	"Doing $($Task.Name)..."
	$Inputs > $Outputs
}

# Synopsis: Log temp files using "file".
file Task2 $GetTmpFiles Task2.log {
	"Doing $($Task.Name)..."
	$Inputs > $Outputs
}

# Synopsis: Partial "task" references "file" and uses its output as input.
task Task3 -Partial -Inputs Task2.log -Outputs Task3.log Task2, {process{
	"Doing $($Task.Name)..."
	Get-Content $_ > $2
}}

# Synopsis: Partial "file" references "task" and uses its output as input.
file Task4 -Partial Task1.log Task4.log Task1, {process{
	"Doing $($Task.Name)..."
	Get-Content $_ > $2
}}
