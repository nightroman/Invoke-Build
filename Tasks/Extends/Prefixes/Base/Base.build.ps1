<#
.Synopsis
	Base build.
#>

param(
	$Configuration = 'Debug'
)

# Synopsis: Name with prefix.
task my::Task {
}

# Synopsis: Should work.
task Required {
	"Base $Configuration"
}

# Synopsis: May fail.
task Optional {
	"Base $Configuration"
}

# Synopsis: Builds all the things.
task Build Required, ?Optional, {
	"Base $Configuration"
}

# Synopsis: Default task.
task . Build
