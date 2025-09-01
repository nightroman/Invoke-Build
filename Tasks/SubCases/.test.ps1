
# Default task of case1 with default parameters.
task case1 {
	($r = Invoke-Build -Case case1)
	assert ($r -like 'case file     : case1\case1.tasks.ps1')
	assert ($r -like 'configuration : Release')
	assert ($r -like 'var1          : root value 1')
}

# Default task of case2 with custom parameters.
task case2 {
	($r = Invoke-Build -Case case2 -Configuration Debug)
	assert ($r -like 'case file     : case2\case2.tasks.ps1')
	assert ($r -like 'configuration : Debug')
	assert ($r -like 'var1          : changed by case2')
}

# Common root task in case1.
task case1_root1 {
	($r = Invoke-Build root1 -Case case1)
	assert ($r -like 'case : *\case1')
	assert ($r -like 'var1 : root value 1')
}

# Common root task in case2.
task case2_root1 {
	($r = Invoke-Build root1 -Case case2)
	assert ($r -like 'case : *\case2')
	assert ($r -like 'var1 : changed by case2')
}
