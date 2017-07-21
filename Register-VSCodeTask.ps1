
<#PSScriptInfo
.VERSION 0.0.1
.AUTHOR Roman Kuzmin
.COPYRIGHT (c) 2011-2017 Roman Kuzmin
.TAGS Invoke, Task, Invoke-Build, VSCode
.GUID 025392f2-b15a-453c-8715-dc989cbc32bc
.LICENSEURI http://www.apache.org/licenses/LICENSE-2.0
.PROJECTURI https://github.com/nightroman/Invoke-Build
#>

<#
.Synopsis
	Registers Invoke-Build tasks as VSCode tasks.

.Description
	The script calls Register-EditorTask for tasks of the default or specified
	build script. It is supposed to be called from a VSCode profile.

	Only tasks with certain names are included. They contain alphanumeric
	characters, "_", ".", and "-", with the first character other than "-".

.Parameter BuildFile
		Specifies the build script path, absolute or relative. By default it is
		the default script in the current location, i.e. in the workspace root.
.Parameter InvokeBuild
		Specifies the Invoke-Build.ps1 path, absolute or relative. The default
		is "Invoke-Build", either the script in the path or the module command.

.Example
	> Register-VSCodeTask
	This command registers tasks of the default build script.
#>

[CmdletBinding()]
param(
	[string]$BuildFile,
	[string]$InvokeBuild = 'Invoke-Build'
)

trap {$PSCmdlet.ThrowTerminatingError($_)}
$ErrorActionPreference = 'Stop'

# Invoke-Build part for commands
$InvokeBuild2 = if ($InvokeBuild -eq 'Invoke-Build') {
	'Invoke-Build'
}
else {
	"& '{0}'" -f $InvokeBuild.Replace('\', '/').Replace("'", "''")
}

# get all tasks
$all = & $InvokeBuild ?? -File $BuildFile

# register tasks
$BuildFile2 = if ($BuildFile) {" -File '{0}'" -f $BuildFile.Replace('\', '/').Replace("'", "''")} else {''}
foreach ($task in $all.Values) {
	$name = $task.Name
	if ($name -match '[^\w\.\-]|^-') {
		continue
	}
	$Command = '{0} -Task {1}{2}' -f $InvokeBuild2, $name, $BuildFile2
	Register-EditorTask -Name $name -Source Invoke-Build -Command $Command
}
