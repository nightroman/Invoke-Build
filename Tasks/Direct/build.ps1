
<#
.Synopsis
	A build script invokable directly by PowerShell

.Description
	This is a build script which can be invoked either by Invoke-Build or
	directly as a normal PowerShell script. In the latter case, it calls
	Invoke-Build with properly passed parameters and returns.

.Parameter Tasks
	Specifies the tasks to be invoked on direct calls. It should not be used by
	the script because on normal calls by Invoke-Build it is not set. Other
	parameters are usual build script parameters.

.Example
	./build.ps1
	Invoke the default task.
.Example
	./build.ps1 t1, t2 -Param1 bar -Param2 42
	Invoke tasks t1 and t2 with some parameters.
#>

param(
	[Parameter(Position=0)]
	$Tasks,
	$Param1,
	$Param2
)

# The trick: if it is not called by Invoke-Build then recall and return.
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
	Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
	return
}

# The usual build script stuff.
task t1 {
	"Param1 = $Param1"
}
task t2 {
	"Param2 = $Param2"
}
