
param(
	$Platform = (property Platform x64)
)

$B2_Platform = $Platform

task test1 {
	$Platform
	equals $Platform $B2_Platform
}
