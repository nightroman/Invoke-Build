<#
.Synopsis
	Acknowledged issues and various facts.

.Link
	https://github.com/nightroman/Invoke-Build/tree/main/Tasks/Bugs
#>

### Lost colors

# Synopsis: Invoke-Build output loses colors.
# The culprit is Format-Table -AutoSize.
# Works fine in PS Core with ANSI.
task footer_lost_color {
	Get-Process svchost | Format-Table Name, PM -AutoSize
	Get-Process svchost | Select-Object Name, PM
}

# Synopsis: Invoke-Build output loses colors - workaround.
# Use Out-String after Format-* cmdlets.
task footer_lost_color_workaround {
	Get-Process svchost | Format-Table Name, PM -AutoSize | Out-String
	Get-Process svchost | Select-Object Name, PM | Out-String
}

### Colors from job builds and remote builds

# Synopsis: Some colored output for other tests.
task output_with_color {
	print Magenta 'Output from output_with_color'
}

# Synopsis: Colored output of a build started by Start-Job.
task output_with_color_as_job {
	$env:_140620_191326 = $BuildFile
	$job = Start-Job {
		Set-StrictMode -Version Latest # does not fail
		Invoke-Build output_with_color $env:_140620_191326
	}
	$job | Wait-Job | Receive-Job
}

# Synopsis: Colored output of a remote build.
task output_with_color_remote {
	$BuildFile > $env:TEMP\_140620_191326
	Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock {
		Set-StrictMode -Version Latest # does not fail
		$file = Get-Content $env:TEMP\_140620_191326
		Invoke-Build output_with_color $file
	}
	Remove-Item $env:TEMP\_140620_191326
}

###	How to get Invoke-Build location
<#
	Normal build scripts do not usually need this.
	But some tests and advanced tools may need this.

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
task how_to_get_ib_directory {
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

<#
	Synopsis: Condition and related targets

	MSBuild processing of a target:
	- Condition is checked before related targets.
	- If Condition=true then invoke DependsOnTargets.
	- Invoke BeforeTargets always (unlike IB).
	- If Condition=true then invoke own tasks.
	- Invoke AfterTargets always (unlike IB).

	https://github.com/nightroman/Invoke-Build/issues/51
	https://github.com/nightroman/Invoke-Build/blob/main/Docs/Comparison-with-MSBuild.md
#>
task condition_and_targets {
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
