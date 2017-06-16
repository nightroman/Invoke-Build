
<#
.Synopsis
	Inline build with some tests.
#>

$MyFile = $MyInvocation.MyCommand.Path
$MyRoot = Split-Path $MyFile

Invoke-Build * -Summary {
	task TestBuildFile {
		$BuildFile
		equals $BuildFile $MyFile
	}
	task TestBuildRoot {
		$BuildRoot
		equals $BuildRoot $MyRoot
	}
}
