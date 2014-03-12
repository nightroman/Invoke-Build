
<#
.Synopsis
	Invoke-Build.ps1 wrapper.

.Description
	This script calls Invoke-Build.ps1 with additional options.
	It is designed for mostly interactive use in command lines.

	Dynamic script parameters. If a build script parameters do not conflict
	with Build.ps1 parameters then they can be specified for Build.ps1 itself.

.Parameter Task
		See: help Invoke-Build -Parameter Task
.Parameter File
		See: help Invoke-Build -Parameter File

		If the file is not specified and the default file is not found then a
		script defined by $env:InvokeBuildGetFile is called if it exists. It
		optionally gets a build file path for the current location. If the file
		is still not defined then this script searches for default build files
		in all parent directories of the current.
.Parameter Parameters
		See: help Invoke-Build -Parameter Parameters
		It cannot be used together with dynamic parameters.
.Parameter Checkpoint
		See: help Invoke-Build -Parameter Checkpoint
.Parameter WhatIf
		See: help Invoke-Build -Parameter WhatIf
.Parameter Tree
		Tells to analyse task references and show parent tasks and child trees
		for the specified or all tasks. Tasks are not invoked. Use the switch
		Comment in order to show task comments as well.
.Parameter Comment
		Tells to show code comments preceding each task in the task tree. It is
		used together with the switch Tree or on its own.
.Parameter Summary
		Tells to show task summary information after building.
.Parameter NoExit
		Tells to prompt "Press enter to exit".

.Inputs
	None.
.Outputs
	Build output or requested information.
#>

param
(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][hashtable]$Parameters,
	[string]$Checkpoint,
	[switch]$WhatIf,
	[switch]$Tree,
	[switch]$Comment,
	[switch]$Summary,
	[switch]$NoExit
)
DynamicParam {
	$private:path = $null
	$private:names =
	'Task', 'File', 'Parameters', 'Checkpoint', 'WhatIf', 'Tree', 'Comment', 'Summary', 'NoExit',
	'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'ErrorVariable', 'WarningVariable', 'OutVariable', 'OutBuffer'

	$Task = Get-Variable -Name [T]ask -ValueOnly -Scope 0
	if ($Task -eq '**') {return}

	try {
		# default
		$path = Get-Variable -Name [F]ile -ValueOnly -Scope 0
		if ($path) {
			$path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($path)
			if (![System.IO.File]::Exists($path)) {throw "Missing script '$path'."}
		}
		else {
			if ([System.IO.File]::Exists($env:InvokeBuildGetFile)) {
				$path = & $env:InvokeBuildGetFile
			}
			if (!$path) {
				function Get-BuildFile($Path)
				{if(($_=[System.IO.Directory]::GetFiles($Path, '*.build.ps1')).Count -eq 1){$_}else{$_ -like '*\.build.ps1'}}

				$_ = $PSCmdlet.GetUnresolvedProviderPathFromPSPath('')
				do {$path = Get-BuildFile $_} while(!$path -and ($_ = Split-Path $_))
			}
			if (!$path) {throw 'Missing default script.'}
		}

		# Parameters?
		if (Get-Variable -Name [P]arameters -Scope 0) {return}

		# get command
		$private:command = Get-Command -Name $path -CommandType ExternalScript -ErrorAction 1
		if (!$command.Parameters) {return}

		# dynamic parameters
		$private:param = New-Object Management.Automation.RuntimeDefinedParameterDictionary
		$private:attrs = New-Object Collections.ObjectModel.Collection[Attribute]
		$attrs.Add((New-Object Management.Automation.ParameterAttribute))
		foreach($_ in $command.Parameters.Values) {
			if ($names -notcontains $_.Name) {
				$param.Add($_.Name, (New-Object Management.Automation.RuntimeDefinedParameter $_.Name, $_.ParameterType, $attrs))
			}
		}
		$param
	}
	catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
}
end {
	# Hide variables
	$private:_Task = $Task
	$private:_File = if ($File) {$File} else {$path}
	$private:_Parameters = $Parameters
	$private:_Checkpoint = $Checkpoint
	$private:_Tree = $Tree
	$private:_Comment = $Comment
	$private:_Summary = $Summary
	$private:_NoExit = $NoExit
	$private:query = $Task -eq '?' -or $Task -eq '??'
	Remove-Variable Task, File, Parameters, Checkpoint, Tree, Comment, Summary, NoExit

	# To amend errors
	try {
		### Show tree
		if ($_Tree -or $_Comment) {
			# get tasks
			$tasks = Invoke-Build ?? -File:$_File -Parameters:$_Parameters

			function ShowTaskTree($Task, $Step, $Comment)
			{
				if ($Step -eq 0) {''}
				$tab = '    ' * $Step
				++$Step

				# comment
				if ($Comment) {
					foreach($_ in GetTaskComment $Task) {
						if ($_) {$tab + $_}
					}
				}

				# name, parents
				$info = $tab + $Task.Name
				$reference = $references[$Task]
				if ($reference.Count) {
					$info += ' (' + (($reference.Keys | Sort-Object) -join ', ') + ')'
				}
				$info

				# task jobs
				foreach($_ in $Task.Job) {
					if ($_ -is [string]) {
						ShowTaskTree $tasks[$_] $Step $Comment
					}
					else {
						$tab + '    {}'
					}
				}
			}

			# gets comments
			$file2docs = @{}
			function GetTaskComment($Task) {
				$file = $Task.InvocationInfo.ScriptName
				$docs = $file2docs[$file]
				if (!$docs) {
					$docs = New-Object System.Collections.Specialized.OrderedDictionary
					$file2docs[$file] = $docs
					foreach($token in [System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $file), [ref]$null)) {
						if ($token.Type -eq 'Comment') {
							$docs[[object]$token.EndLine] = $token.Content
						}
					}
				}
				$rem = ''
				for($1 = $Task.InvocationInfo.ScriptLineNumber - 1; $1 -ge 1; --$1) {
					$doc = $docs[[object]$1]
					if (!$doc) {break}
					$rem = $doc.Replace("`t", '    ') + "`n" + $rem
				}
				[regex]::Split($rem.TrimEnd(), '[\r\n]+')
			}

			# references
			$references = @{}
			foreach($it in $tasks.Values) {
				$references[$it] = @{}
			}
			foreach($it in $tasks.Values) { foreach($job in $it.Job) { if ($job -is [string]) {
				$references[$tasks[$job]][$it.Name] = 0
			}}}

			# show trees
			foreach($name in $(if ($_Task -and !$query) {$_Task} else {$tasks.Keys})) {
				ShowTaskTree $tasks[$name] 0 $_Comment
			}
			return
		}

		function *Err*($Text, $Info)
		{"ERROR: $Text`r`n$($Info.PositionMessage.Trim())"}

		# param
		if (!$_Parameters) {
			foreach($_ in $PSBoundParameters.GetEnumerator()) {
				if ($names -notcontains $_.Key) {
					if ($_Parameters) { $_Parameters.Add($_.Key, $_.Value) }
					else { $_Parameters = @{$_.Key = $_.Value} }
				}
			}
		}

		### Build
		try {
			Invoke-Build -Task:$_Task -File:$_File -Parameters:$_Parameters -Checkpoint:$_Checkpoint -WhatIf:$WhatIf -Result:Result
		}
		finally {
			# summary
			if ($_Summary -and !$query) {
				Write-Host @'

---------- Build Summary ----------

'@
				foreach($_ in $Result.Tasks) {
					Write-Host ('{0,-16} {1} {2}:{3}' -f $_.Elapsed, $_.Name, $_.InvocationInfo.ScriptName, $_.InvocationInfo.ScriptLineNumber)
					if ($_.Error) {
						Write-Host -ForegroundColor Red (*Err* $_.Error $_.Error.InvocationInfo)
					}
				}
			}
		}
	}
	catch {
		if ($_.InvocationInfo.ScriptName -ne $MyInvocation.MyCommand.Path) {throw}
		$PSCmdlet.ThrowTerminatingError($_)
	}
	finally {
		if ($_NoExit) { Read-Host 'Press enter to exit' }
	}
}
