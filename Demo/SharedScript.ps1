
<#
.Synopsis
	Functions shared between build scripts.
#>

<#
.Synopsis
	Formats error information for testing.

.Description
	Code "$$ | Out-String" does not work in some hosts with strict mode. It
	works but adds errors like "Width is not found" and gets empty text.
#>
function Format-Error($$) {
	@"
$$
$($$.InvocationInfo.PositionMessage.Trim().Replace("`n", "`r`n"))
+ $($$.CategoryInfo)
"@
}
