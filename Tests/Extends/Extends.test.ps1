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

task same-parameter-name {
	try { throw Invoke-Build same-parameter-name.build.ps1 }
	catch {
		"$_"
		assert ("$_" -like "Cannot add parameter 'Base1' of '*\same-parameter-name.build.ps1': *")
	}
}

# Should result in dot-task redefined in Test.
# Redefined for dot-task is omitted in v5.14.0.
task All {
	Invoke-Build * ..\..\Tasks\Extends\Multilevel -Base1 b1 -More1 m1 -Test1 t1
}

# Should trigger Enter/Exit-Build of More, even with no tasks from More.
task BaseTask1 {
	Invoke-Build BaseTask1 ..\..\Tasks\Extends\Multilevel -Base1 b1 -More1 m1 -Test1 t1
}

# Test multiple case.
task Multiple {
	Invoke-Build * ..\..\Tasks\Extends\Multiple -Base1 b1 -More1 m1 -Test1 t1
}

task WhatIf {
	Invoke-Build MoreTask1 ..\..\Tasks\Extends\Multilevel\More\More.build.ps1 -WhatIf
}

# More1 and More2 are shown, found in code.
task ShowHelp {
	Show-TaskHelp.ps1 MoreTask1 ..\..\Tasks\Extends\Multilevel\More\More.build.ps1
}

# More1 and More2 are not shown, -NoCode.
# Cover default parameters // v5.14.1 Show-TaskHelp recalls itself by IB
task ShowHelpNoCode {
	$r = Show-TaskHelp.ps1 MoreTask1 ..\..\Tasks\Extends\Multilevel\More\More.build.ps1 -NoCode -Format {$args[0]}
	$r = $r.Parameters.ForEach('name') -join '//'
	equals $r Base1//Base2//MoreX
}
