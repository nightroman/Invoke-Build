
# Should result in dot-task redefined in Test.
# Redefined for dot-task is omitted in v5.14.0.
task All {
	Invoke-Build * ..\..\Tasks\Extends\Multilevel -Base1 b1 -More1 m1 -Test1 t1
}

# Should trigger Enter/Exit-Build of More, even with no tasks from More.
task BaseTask1 {
	Invoke-Build BaseTask1 ..\..\Tasks\Extends\Multilevel -Base1 b1 -More1 m1 -Test1 t1
}

# Test multiple case.
task Multiple {
	Invoke-Build * ..\..\Tasks\Extends\Multiple -Base1 b1 -More1 m1 -Test1 t1
}

task same-parameter-name {
	try { throw Invoke-Build same-parameter-name.build.ps1 }
	catch {
		"$_"
		assert ("$_" -like "Cannot add parameter 'Base1' of '*\same-parameter-name.build.ps1': *")
	}
}
