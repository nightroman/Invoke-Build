
<#
.Synopsis
	Test Get-BuildSynopsis

.Example
	Invoke-Build * Synopsis.test.ps1
#>

# This task has no synopsis.
task NoSinopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r
}

# Synopsis: Simple synopsis.
task SimpleSinopsis {
	($r = Get-BuildSynopsis $Task)
	equals $r 'Simple synopsis.'
}

##   Synopsis   ::Funny formatted.
task FunnySinopsis {
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
