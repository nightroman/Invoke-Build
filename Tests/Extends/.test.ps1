<#
.Synopsis
	Test Extends, Show-TaskHelp, Invoke-Build -WhatIf.

.Description
	2025-05-25-1251 MoreTask1 deliberately omits known used parameters and environment in comments.
	But `Show-TaskHelp` and `Invoke-Build -WhatIf` should discover them by BaseTask1.
	- Base1, Base2, BaseEnv ~ BaseTask1 help
	- More1, More2 ~ code
	- MoreX, MoreEnv ~ comment
#>

Set-StrictMode -Version 3

[string]$DemoRoot = Resolve-Path ..\..\Tasks\Extends

# Should result in dot-task redefined in Test.
# Redefined for dot-task is omitted in v5.14.0.
# Covers BuildRoots and [System.IO.Path]::GetFullPath()
task All {
	Invoke-Build * $DemoRoot\Multilevel -Base1 b1 -More1 m1 -Test1 t1 -InformationVariable iv
	equals $iv.Count 3
	assert ($iv[0] -match '^Base BuildRoots .*?[\\/]Extends[\\/]Base .*?[\\/]Extends[\\/]Multilevel[\\/]More .*?[\\/]Extends[\\/]Multilevel$')
	assert ($iv[1] -match '^More BuildRoots .*?[\\/]Extends[\\/]Multilevel[\\/]More .*?[\\/]Extends[\\/]Multilevel$')
	assert ($iv[2] -match '^Test BuildRoots .*?[\\/]Extends[\\/]Multilevel$')
}

# Should trigger Enter/Exit-Build of More, even with no tasks from More.
task BaseTask1 {
	Invoke-Build BaseTask1 $DemoRoot\Multilevel -Base1 b1 -More1 m1 -Test1 t1
}

# Test multiple case.
task Multiple {
	Invoke-Build * $DemoRoot\Multiple -Base1 b1 -More1 m1 -Test1 t1
}

# v5.14.2 Cover position of redefined task.
task Help {
	Invoke-Build ? $DemoRoot\Multilevel\Test.build.ps1 | Out-String
}

task WhatIf {
	Invoke-Build MoreTask1 $DemoRoot\Multilevel\More\More.build.ps1 -WhatIf
}

# More1 and More2 are shown, found in code.
task ShowHelp {
	Show-TaskHelp.ps1 MoreTask1 $DemoRoot\Multilevel\More\More.build.ps1
}

# More1 and More2 are not shown, -NoCode.
# Cover default parameters // v5.14.1 Show-TaskHelp recalls itself by IB
task ShowHelpNoCode {
	$r = Show-TaskHelp.ps1 MoreTask1 $DemoRoot\Multilevel\More\More.build.ps1 -NoCode -Format {$args[0]}
	$r = $r.Parameters.ForEach('name') -join '//'
	equals $r Base1//Base2//MoreX
}

task Prefixes {
	Invoke-Build Build $DemoRoot\Prefixes
}

task Checkpoint {
    Build-Checkpoint z.clixml -Preserve @{Task='Build'; File="$DemoRoot\Prefixes"; Configuration='Test'}
    $r = Import-Clixml z.clixml
    $r.Done
    remove z.clixml
}

task Dot {
	Invoke-Build -File $DemoRoot\Prefixes -WhatIf
}

task Next {
	Invoke-Build . $DemoRoot\Prefixes\Next
}

task v5.14.12.parameters {
	Invoke-Build test1 v5.14.12.parameters\1.build.ps1 -Platform Win32
}

task v5.14.14.prefixes {
	Invoke-Build main v5.14.14.prefixes\1.build.ps1
}
