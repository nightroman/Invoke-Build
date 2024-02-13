<#
.Synopsis
	A build script directly invokable by PowerShell

.Description
	This is a build script which can be invoked either by Invoke-Build or
	directly as a normal PowerShell script. In the latter case, it calls
	Invoke-Build with passed parameters and returns.

	For direct calls only, you can name the script as you like (*.ps1).
	But in order to be recognised as the default script by Invoke-Build
	and some tools you should use the conventional pattern *.build.ps1.

.Parameter Tasks
	Specifies the tasks to be invoked on direct calls. It should not be used by
	the script because on normal calls by Invoke-Build it is not set. Other
	parameters are usual build script parameters.

.Example
	> ./my.build.ps1
	Invoke the default task

.Example
	> ./my.build.ps1 t1, t2 -Param1 bar -Param2 42
	Invoke tasks t1 and t2 with some parameters

.Example
	> Invoke-Build t1, t2 -Param1 bar -Param2 42
	Ditto by Invoke-Build (script name must be *.build.ps1)
#>

param(
	[Parameter(Position=0)]
	[string[]]$Tasks,
	$Param1,
	$Param2
)

# call the build engine with this script and return
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
	return Invoke-Build $Tasks $MyInvocation.MyCommand.Path @PSBoundParameters
}

# the usual build script
task t1 {
	"Param1 = $Param1"
}
task t2 {
	"Param2 = $Param2"
}
