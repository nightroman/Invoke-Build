
# Test the required path.
requires -Path README.md

# Synopsis: Some task using the required path.
task MyPath {
	"MyPath Length = $((Get-Item README.md).Length)"
}
