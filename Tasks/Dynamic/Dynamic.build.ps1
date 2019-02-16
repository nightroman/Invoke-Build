<#
.Synopsis
	Dynamic script with dynamic tasks

.Description
	For each directory in the parent directory we generate a toy incremental task.
	The inputs are the directory files, the output is the file z.X.log with input
	file paths, where X is the directory name.

	When the script is called the first time all tasks are invoked and all
	z.X.log files are created. On the immediate next call all the tasks are
	skipped because their outputs are up to date. On further calls if input
	files are changed then related output files are updated.

.Link
	https://github.com/nightroman/Invoke-Build/issues/141
#>

# Synopsis: Create z.X.log files with file paths of each parent directory.
task DynamicIncrementalTasks {
	# invoke all tasks (*) in a dynamic script with dynamic incremental tasks
	Invoke-Build * {
		# for each directory in the parent directory create a task
		foreach($dir in Get-ChildItem .. -Directory) {
			# input files and the output file name
			$in = Get-ChildItem -LiteralPath $dir.FullName -File
			$out = "z.$($dir.Name).log"

			# dynamically added incremental task
			task $out -Inputs $in -Outputs $out {
				"Writing $Outputs"
				$Inputs | Set-Content $Outputs
			}
		}
	}
}

# Synopsis: Remove generated z.*.log files.
task Clean {
	remove z.*.log
}
