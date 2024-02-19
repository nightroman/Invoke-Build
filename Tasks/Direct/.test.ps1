
task Direct {
	($r = .\Project.build.ps1 t1, t2 -Param1 bar -Param2 42)
	assert ($r -contains 'Param1 = bar')
	assert ($r -contains 'Param2 = 42')
}

task Engine {
	($r = Invoke-Build t1, t2 -Param1 bar -Param2 42)
	assert ($r -contains 'Param1 = bar')
	assert ($r -contains 'Param2 = 42')
}
