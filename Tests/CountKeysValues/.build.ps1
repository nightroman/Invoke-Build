# Build script with fixed IDictionary Count, Keys, Values issues.
# See https://github.com/nightroman/Invoke-Build/issues/173

param($Count, $Keys, $Values)

task count {}

task keys {}

task values {}

task . count, keys, values, {
	"param($Count, $Keys, $Values)"
	$env:Count
	$env:Keys
	$env:Values
}
