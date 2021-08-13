<#
.Synopsis
	Task job with custom attributes with extra actions.
#>

# This attribute tells to initialize and dispose the resource "Foo1".
class UsesFoo1 : System.Attribute {
	Init() {
		Write-Host 'init1'
	}
	Kill() {
		Write-Host 'kill1'
	}
}

# This attribute tells to initialize and dispose the resource "Foo2".
class UsesFoo2 : System.Attribute {
	Init() {
		Write-Host 'init2'
	}
	Kill() {
		Write-Host 'kill2'
	}
}

# It is called before invoking task jobs.
Enter-BuildJob {
	param($Job)
	foreach($attribute in $Job.Attributes) {
		$attribute.Init()
	}
}

# It is called after invoking task jobs.
Exit-BuildJob {
	foreach($attribute in $Job.Attributes) {
		$attribute.Kill()
	}
}

# This task has a job with custom attributes.
# They tell to initialize and dispose stuff.
task task1 {
	[UsesFoo1()]
	[UsesFoo2()]
	param()
}
