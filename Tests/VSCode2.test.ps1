
<#
.Synopsis
	Tests Register-VSCodeTask.ps1
#>

. ./Shared.ps1

Enter-BuildJob {
	. Set-Mock Register-EditorTask {
		param ($Name, $Source, $Command)
		$PSBoundParameters
	}
}

function Find-Task($Tasks, $Name) {
	foreach ($task in $Tasks) {
		if ($task.Name -eq $Name) {
			$task
		}
	}
}

# default script in this folder
task OmittedPaths {
	$r1 = Register-VSCodeTask.ps1
	$r2 = Invoke-Build ??
	equals $r1.Count $r2.Count
	for ($i = $r1.Count; --$i -ge 0) {
		$t1 = $r1[$i]
		$t2 = $r2.Item($i)
		equals $t1.Name $t2.Name
		equals $t1.Source Invoke-Build
		equals $t1.Command "Invoke-Build -Task $($t1.Name)"
	}
}

# this script (full path) + IB (full path)
task FullPaths {
	$InvokeBuild = *Path ..\Invoke-Build.ps1
	$r = Register-VSCodeTask.ps1 $BuildFile $InvokeBuild
	$t = $r[0]
	equals $t.Name OmittedPaths
	equals $t.Source Invoke-Build
 	equals $t.Command ("& '{0}' -Task OmittedPaths -File '{1}'" -f $InvokeBuild.Replace('\', '/'), $BuildFile.Replace('\', '/'))
}
