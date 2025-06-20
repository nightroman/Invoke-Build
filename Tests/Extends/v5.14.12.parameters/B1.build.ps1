
param(
	$Platform = (property Platform x64)
)

$B1_Platform = $Platform

task test1 {
	$Platform
	equals $Platform $B1_Platform
}
