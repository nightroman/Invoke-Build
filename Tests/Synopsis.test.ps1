<#
.Synopsis
	Tests Get-BuildSynopsis.
#>

# Synopsis: Simple synopsis.
task SimpleSynopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r 'Simple synopsis.'
}

# This task has no synopsis.
task NoSynopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r
}

##   Synopsis   ::Funny formatted.
task FunnySynopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r ':Funny formatted.'
}

<#
Synopsis: Multiline synopsis.
Fixed: v4.1.1 MultilineSynopsis is returned with \r in the end.
#>
task MultilineSynopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r 'Multiline synopsis.'
}

# Synopsis: Comments with empty lines.

# Keep these separated by empty lines.

# Fixed #111: v4.2.0 cannot go through empty lines.

task SkipEmptyLines {
	($r = Get-BuildSynopsis $Task)
	equals $r 'Comments with empty lines.'
}

<#
.Synopsis
	PS style synopsis.
	This is not synopsis.
.Description
	Issue #165, feature request.
#>
task StandardSynopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r 'PS style synopsis.'
}
