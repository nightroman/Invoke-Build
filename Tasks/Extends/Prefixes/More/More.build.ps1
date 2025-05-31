<#
.Synopsis
	More build.
#>

param(
	$Configuration = 'Release'
)

# Synopsis: Should work.
task Required {
	"More $Configuration"
}

# Synopsis: May fail.
task Optional {
	"More $Configuration"
}

# Synopsis: Builds all the things.
task Build Required, ?Optional, {
	"More $Configuration"
}

# Synopsis: Default task.
task . Build
