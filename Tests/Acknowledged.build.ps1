
<#
.Synopsis
	Acknowledged issues and various facts.
#>

# Synopsis: Empty task used by other tests.
task dummy

### Dynamic switch

<#
Synopsis: Shows why dynamic switches should be used after positional arguments.
https://github.com/nightroman/Invoke-Build/issues/4
#>
task Dynamic-Switch-Issue {
	# temp directory
	Push-Location (mkdir z -ErrorAction 0)

	# temp build script
	{
		param($Param = 'data1', [switch]$Switch)
		task task1 {"1 $Param $Switch"}
		task task2 {"2 $Param $Switch"}
	} > z.build.ps1

	# Works fine when a dynamic switch is after positional arguments.
	# The task2 is invoked as expected.

	($r = Invoke-Build task2 -Switch | Out-String)
	assert ($r -like '*Task /task2*2 data1 True*')

	# Works incorrectly when a dynamic switch is before positional arguments.
	# The task1 is invoked unexpectedly.

	($r = Invoke-Build -Switch task2 | Out-String)
	assert ($r -like '*Task /task1*1 data1 True*')

	# Or even fails on parsing the parameters.
	# Note shifted arguments, z.build.ps1 is treated as an argument of -Task.

	($r = try {Invoke-Build -Switch task2 z.build.ps1} catch {$_})
	assert ($r -like "*Missing task 'z.build.ps1'*")

	Pop-Location
	Remove-Item z -Force -Recurse
}

### Lost colors

<#
Synopsis: Invoke-Build output looses colors.
The culprit is Format-Table -AutoSize.
Tested with PowerShell v2, v3, v4.
#>
task Footer-Lost-Color {
	Get-Process svchost | Format-Table Name, PM -AutoSize
	Get-Process svchost | Select-Object Name, PM
}

<#
Synopsis: Invoke-Build output looses colors - workaround.
Out-String is recommended with Format-* cmdlets in builds.
#>
task Footer-Lost-Color-Workaround {
	Get-Process svchost | Format-Table Name, PM -AutoSize | Out-String
	Get-Process svchost | Select-Object Name, PM
}

### Colors from job builds and remote builds

# Synopsis: Some colored output for other tests.
task Output-With-Color {
	Write-Build Magenta 'Output from Output-With-Color'
}

# Synopsis: Colored output of a build started by Start-Job.
task Output-With-Color-As-Job {
	$env:_140620_191326 = $BuildFile
	$job = Start-Job {
		Set-StrictMode -Version Latest # does not fail
		Invoke-Build Output-With-Color $env:_140620_191326
	}
	$job | Wait-Job | Receive-Job
}

# Synopsis: Colored output of a remote build.
task Output-With-Color-Remote {
	$BuildFile > $env:TEMP\_140620_191326
	Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock {
		Set-StrictMode -Version Latest # does not fail
		$file = Get-Content $env:TEMP\_140620_191326
		Invoke-Build Output-With-Color $file
	}
	Remove-Item $env:TEMP\_140620_191326
}

###	How to get Invoke-Build location
<#
	This is needed in order to resolve paths to other tools with their
	locations known to be relative to Invoke-Build.

	1. In build scripts, tasks, functions:

		Split-Path ((Get-Alias Invoke-Build).Definition)

	2. In build scripts and tasks, not in functions:

		Split-Path $MyInvocation.ScriptName

	or in PowerShell v3.0+

		$MyInvocation.PSScriptRoot
#>

# How to get Invoke-Build directory in a script.
$IBRoot1 = Split-Path $MyInvocation.ScriptName

# How to get Invoke-Build directory in a function.
function Get-IBRootInFunction {
	# correct way in a function
	$IBRootOK = Split-Path ((Get-Alias Invoke-Build).Definition)
	$IBRootOK

	# this gets something else
	$IBRootKO = Split-Path $MyInvocation.ScriptName
	assert ($IBRootKO -ne $IBRootOK)
}

# Synopsis: How to get Invoke-Build directory in a task.
# It also tests directories got from script and function.
task How-To-Get-Invoke-Build-Directory {
	# get it in the task scope
	$IBRoot2 = Split-Path $MyInvocation.ScriptName

	# get it in a function
	$IBRoot3 = Get-IBRootInFunction

	# show 3 values
	$IBRoot1
	$IBRoot2
	$IBRoot3

	# test 3 values are the same
	equals $IBRoot1 $IBRoot2
	equals $IBRoot2 $IBRoot3
}

### Invoke-Build overhead

task Measure-Invoke-Build-Overhead {
	# invoke this script as a normal script
	$r1 = Measure-Command {& $BuildFile}
	$r1.TotalMilliseconds

	# invoke this script as a build script
	$r2 = Measure-Command {Invoke-Build dummy $BuildFile}
	$r2.TotalMilliseconds

	# Invoke-Build overhead
	($r2 - $r1).TotalMilliseconds
}

<#
	Synopsis: Condition and related targets

	MSBuild processing of a target:
	- Condition is checked before related targets.
	- If Condition=true then invoke DependsOnTargets.
	- Invoke BeforeTargets always (unlike IB).
	- If Condition=true then invoke own tasks.
	- Invoke AfterTargets always (unlike IB).

	See also #51.
	See wiki Comparison-with-MSBuild.md
#>
task Condition-and-related-targets {
	Set-Content z.proj @'
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
	<Target Name="Test" Condition="false" DependsOnTargets="Target1">
		<Message Text="In Test"/>
	</Target>
	<Target Name="Target1">
		<Message Text="In Target1"/>
	</Target>
	<Target Name="Target2" BeforeTargets="Test">
		<Message Text="In Target2"/>
	</Target>
	<Target Name="Target3" AfterTargets="Test">
		<Message Text="In Target3"/>
	</Target>
</Project>
'@

	use * MSBuild
	exec { MSBuild /v:d }

	Remove-Item z.proj
}
