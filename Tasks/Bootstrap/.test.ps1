
task Direct {
	($r = .\Project.build.ps1 Build -Configuration Release)
	assert ($r -contains 'Building Release')
}

task Engine {
	($r = Invoke-Build Build -Configuration Release)
	assert ($r -contains 'Building Release')
}
