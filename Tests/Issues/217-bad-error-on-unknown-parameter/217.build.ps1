<# https://github.com/nightroman/Invoke-Build/issues/217
#152 fixed one issue but added another, cryptic errors.
#217 shifts script parameters positions (+2) avoiding conflicts with IB Task and File.
#>

param(
	$Param1,
	$Param2,
	$Param3
)

task .
