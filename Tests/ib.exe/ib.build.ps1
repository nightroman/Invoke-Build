<#
.Synopsis
	Build script for testing ib.exe
#>

param(
	$p1,
	$p2,
	[switch]$s1,
	[switch]$s2
)

task version {
	"PSVersion=$($PSVersionTable.PSVersion)"
}

task param {
	@"
p1=$p1
p2=$p2
s1=$s1
s2=$s2
"@
}
