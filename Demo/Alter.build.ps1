
<#
.Synopsis
	Tests task parameters After and Before.

.Example
	Invoke-Build . Alter.build.ps1

.Link
	Invoke-Build
	.build.ps1
#>

# These tasks are to be altered below. Imagine for example that they are in
# another script dot-sourced in here and we do not want or can modify it.
task Task1 { 'In Task1' }
task Task2 { 'In Task2' }
task Task3 { 'In Task3' }

# Invoke after Task1 and Task2. NOTE: as far as tasks are invoked once, it is
# actually invoked after Task1 only.
task AfterTask -After Task1, Task2 {
	'In AfterTask'
}

# Invoke before Task1 and Task2. NOTE: as far as tasks are invoked once, it is
# actually invoked before Task1 only.
task BeforeTask -Before Task1, Task2 {
	'In BeforeTask'
}

# Invoke after Task3, fail but allow the build to survive.
task AfterTask3 -After @{Task3=1} {
	throw 'In AfterTask3'
}

# Invoke before Task3, fail but allow the build to survive.
task BeforeTask3 -Before @{Task3=1} {
	throw 'In BeforeTask3'
}

# Run tests.
task . Task1, Task2, Task3
