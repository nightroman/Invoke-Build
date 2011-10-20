
<#
.Synopsis
	Invoke-Build.ps1 wrapper.

.Description
	This script calls Invoke-Build.ps1 with additional options.
	It is mostly designed for interactive use in command lines.

	If the parameter File is not specified and there is no *.build.ps1 files in
	the current location then $env:InvokeBuildGetFile is called if it exists.
	It gets either nothing or the file path based on the current location.

	If File is still not defined then this script searches for *.build.ps1
	candidates in the parent directory tree.

	Parameters are similar to Invoke-Build.ps1 parameters but:
	* There are extra switches: Summary, Tree, Comment.
	* Result is not available, it is used internally.

.Parameter Task
		See: help Invoke-Build -Parameter Task

.Parameter File
		See: help Invoke-Build -Parameter File

		If it is not specified and there is no standard default file then this
		script searches for more candidates. See description for details.

.Parameter Parameters
		See: help Invoke-Build -Parameter Parameters

.Parameter WhatIf
		See: help Invoke-Build -Parameter WhatIf

.Parameter Summary
		Tells to show task summary information after building.

.Parameter Tree
		Tells to analyse task references and show parent tasks and child trees
		for the specified or all tasks. Tasks are not invoked. It throws if
		missing or cyclic task references are found.

		Use the switch Comment in order to show task comments as well.

.Parameter Comment
		Tells to show code comments preceding each task in the task tree. It is
		used together with the switch Tree but now it works on its own as well.
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
	,
	[Parameter()]
	[switch]$Tree
	,
	[Parameter()]
	[switch]$Comment
)

### Resolve the file
if (!$File -and !(Test-Path '*.build.ps1')) {

	# call the script $env:InvokeBuildGetFile
	if ([System.IO.File]::Exists($env:InvokeBuildGetFile)) {
		$File = & $env:InvokeBuildGetFile
	}

	# search in the parent tree
	if (!$File) {
		for($private:dir = Split-Path (Get-Location).ProviderPath;; $private:dir = Split-Path $private:dir) {
			if (!$private:dir) {
				throw "Cannot find *.build.ps1 in the parent tree."
			}
			$private:it = @([System.IO.Directory]::GetFiles($private:dir, '*.build.ps1'))
			if ($private:it.Count -eq 1) {
				$File = $private:it[0]
				break
			}
			elseif ($private:it.Count -ge 2) {
				foreach($private:it in $private:it) {
					if ([System.IO.Path]::GetFileName($private:it) -eq '.build.ps1') {
						$File = $private:it
						break
					}
				}
				if (!$File) {
					throw "Found more than one '*.build.ps1' and none of them is '.build.ps1'."
				}
				break
			}
		}
	}
}

### Show tree
if ($Tree -or $Comment) {
	function ShowTaskTree($Task, $Step, $Done)
	{
		if ($Step -eq 0) {''}
		$tab = '    ' * $Step
		++$Step

		# comment
		if ($Comment) {
			foreach($_ in GetTaskComment $Task) {
				if ($_) {
					$tab + $_
				}
			}
		}

		# name, parents
		$info = $tab + $Task.Name
		if ($Task.Reference.Count) {
			$info += ' (' + (($Task.Reference.Keys | Sort-Object) -join ', ') + ')'
		}
		$info

		# watch cyclic
		$count = 1 + $Done.Add($Task)

		# task jobs
		foreach($_ in $Task.Jobs) {
			if ($_ -is [string]) {
				$job = $BuildList[$_]

				if ($Done.Contains($job)) {
					throw @"
Task '$($Task.Name)': Cyclic reference to '$_'.
$($Task.Info.PositionMessage.Trim().Replace("`n", "`r`n"))
"@
				}

				ShowTaskTree $job $Step $Done
				$Done.RemoveRange($count, $Done.Count - $count)
			}
			else {
				$tab + '    {..}'
			}
		}
	}

	# gets comments
	$file2docs = @{}
	function GetTaskComment($Task) {
		$file = $Task.Info.ScriptName
		$docs = $file2docs[$file]
		if (!$docs) {
			$docs = New-Object System.Collections.Specialized.OrderedDictionary
			$file2docs[$file] = $docs
			try {
				foreach($token in [System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $file), [ref]$null)) {
					if ($token.Type -eq 'Comment') {
						$docs[$token.EndLine] = $token.Content
					}
				}
			}
			catch {
				Write-Warning $_
			}
		}
		$comment = ''
		for($$ = $Task.Info.ScriptLineNumber - 1; $$ -ge 1; --$$) {
			$doc = $docs[$$]
			if (!$doc) {
				break
			}
			$comment = $doc.Replace("`t", '    ') + "`n" + $comment
		}
		[regex]::Split($comment.TrimEnd(), '[\r\n]+')
	}

	# get the tasks as $BuildList
	Invoke-Build ? -File:$File -Parameters:$Parameters -Result BuildList

	# references
	foreach($it in $BuildList.Values) {
		$it | Add-Member -MemberType NoteProperty -Name Reference -Value @{}
	}
	foreach($it in $BuildList.Values) { foreach($job in $it.Jobs) { if ($job -is [string]) {
		$it2 = $BuildList[$job]
		if (!$it2) {
			throw @"
Task '$($it.Name)': Task '$job' is not defined.
$($it.Info.PositionMessage.Trim().Replace("`n", "`r`n"))
"@
		}
		$it2.Reference[$it.Name] = 0
	}}}

	# show trees
	foreach($name in $(if ($Task -and '?' -ne $Task) { $Task } else { $BuildList.Keys })) {
		$it = $BuildList[$name]
		if (!$it) {
			throw "Task '$name' is not defined."
		}
		ShowTaskTree $it 0 ([System.Collections.ArrayList]@())
	}

	return
}

# Hide variables
$private:_Task = $Task
$private:_File = $File
$private:_Parameters = $Parameters
$private:_Summary = $Summary
Remove-Variable Task, File, Parameters, Summary, Tree, Comment

### Build with results
try {
	$Result = if ($_Summary) { 'Result' } else { $null }
	Invoke-Build -Task:$_Task -File:$_File -Parameters:$_Parameters -WhatIf:$WhatIf -Result:$Result
}
finally {
	### Show summary
	if ($_Summary) {
		foreach($_ in $Result.AllTasks) {
			Write-Host ('{0,-16} {1} {2}:{3}' -f $_.Elapsed, $_.Name, $_.Info.ScriptName, $_.Info.ScriptLineNumber)
			if ($_.Error) {
				Write-Host -ForegroundColor Red ($_.Error | Out-String)
			}
		}
	}
}
