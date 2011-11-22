
<#
.Synopsis
	Invoke-Build.ps1 wrapper.

.Description
	This script calls Invoke-Build.ps1 with additional options.
	It is mostly designed for interactive use in command lines.

	If File is not specified and the default file is not found then the script
	defined as $env:InvokeBuildGetFile is called. It optionally gets the file
	path based on the current location.

	If File is still not defined then this script searches for default build
	files in the parent directory tree.

	Parameters are main Invoke-Build parameters and some new:
	* Summary, Tree, Comment.

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

.Parameter Tree
		Tells to analyse task references and show parent tasks and child trees
		for the specified or all tasks. Tasks are not invoked. Use the switch
		Comment in order to show task comments as well.

.Parameter Comment
		Tells to show code comments preceding each task in the task tree. It is
		used together with the switch Tree or on its own.

.Parameter Summary
		Tells to show task summary information after building.
#>

param
(
	[Parameter(Position=0)][string[]]$Task,
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][hashtable]$Parameters,
	[switch]$WhatIf,
	[switch]$Tree,
	[switch]$Comment,
	[switch]$Summary
)

### Hook
$BuildHook = @{
	GetFile = {
		if ([System.IO.File]::Exists($env:InvokeBuildGetFile)) {
			$_ = & $env:InvokeBuildGetFile
			if ($_) {return $_}
		}

		for($dir = Split-Path $PSCmdlet.GetUnresolvedProviderPathFromPSPath(''); $dir; $dir = Split-Path $dir) {
			$_ = Get-BuildFile $dir
			if ($_) {return $_}
		}
	}
}

# Hide variables
$private:_Task = $Task
$private:_File = $File
$private:_Parameters = $Parameters
$private:_Tree = $Tree
$private:_Comment = $Comment
$private:_Summary = $Summary
Remove-Variable Task, File, Parameters, Tree, Comment, Summary

try { # To amend errors

### Show tree
if ($_Tree -or $_Comment) {
	# get tasks
	Invoke-Build ? -File:$_File -Parameters:$_Parameters -Hook:$BuildHook -Result:BuildList

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
		if ($Task.Reference.Count) {
			$info += ' (' + (($Task.Reference.Keys | Sort-Object) -join ', ') + ')'
		}
		$info

		# task jobs
		foreach($_ in $Task.Jobs) {
			if ($_ -is [string]) {
				ShowTaskTree $BuildList[$_] $Step $Comment
			}
			else {
				$tab + '    {..}'
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
			try {
				foreach($token in [System.Management.Automation.PSParser]::Tokenize((Get-Content -LiteralPath $file), [ref]$null)) {
					if ($token.Type -eq 'Comment') {
						$docs[$token.EndLine] = $token.Content
					}
				}
			}
			catch {Write-Warning $_}
		}
		$rem = ''
		for($$ = $Task.InvocationInfo.ScriptLineNumber - 1; $$ -ge 1; --$$) {
			$doc = $docs[$$]
			if (!$doc) {break}
			$rem = $doc.Replace("`t", '    ') + "`n" + $rem
		}
		[regex]::Split($rem.TrimEnd(), '[\r\n]+')
	}

	# references
	foreach($it in $BuildList.Values) {
		$it | Add-Member -MemberType NoteProperty -Name Reference -Value @{}
	}
	foreach($it in $BuildList.Values) { foreach($job in $it.Jobs) { if ($job -is [string]) {
		$BuildList[$job].Reference[$it.Name] = 0
	}}}

	# show trees
	foreach($name in $(if ($_Task -and '?' -ne $_Task) {$_Task} else {$BuildList.Keys})) {
		ShowTaskTree $BuildList[$name] 0 $_Comment
	}
	return
}

function *Err*($Text, $Info)
{"ERROR: $Text`r`n$($Info.PositionMessage.Trim().Replace("`n", "`r`n"))"}

### Build with results
try {
	$Result = if ($_Summary) {'Result'}
	Invoke-Build -Task:$_Task -File:$_File -Parameters:$_Parameters -Hook:$BuildHook -WhatIf:$WhatIf -Result:$Result
}
finally {
	### Show summary
	if ($_Summary) {
		Write-Host @'

---------- Build Summary ----------

'@
		foreach($_ in $Result.AllTasks) {
			Write-Host ('{0,-16} {1} {2}:{3}' -f $_.Elapsed, $_.Name, $_.InvocationInfo.ScriptName, $_.InvocationInfo.ScriptLineNumber)
			if ($_.Error) {
				Write-Host -ForegroundColor Red (*Err* $_.Error $_.Error.InvocationInfo)
			}
		}
	}
}

} catch {
	if ($_.InvocationInfo.ScriptName -ne $MyInvocation.MyCommand.Path) {throw}
	$PSCmdlet.ThrowTerminatingError($_)
}
