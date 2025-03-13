
task publish {
	(Get-ChildItem env:*MSBuild* | Sort-Object Name).ForEach({$_.Name + '=' + $_.Value})
}
