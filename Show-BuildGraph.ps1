
<#
.Synopsis
	Shows Invoke-Build task graph using Graphviz.

.Description
	Requires:
	- Graphviz: http://graphviz.org/
	- Graphviz\bin in the environment variable Graphviz or in the path.

	The script calls Invoke-Build.ps1 in order to get the tasks (WhatIf mode),
	builds the DOT file and calls Graphviz's dot.exe in order to visualize it
	using one of the supported output formats and associated applications.

.Parameter File
		See: help Invoke-Build -Parameter File

.Parameter Output
		The output file path and format specified by extension. For available
		formats simply use unlikely supported one and check the error message.
		The default is 'Graphviz.pdf' in the TEMP directory.

.Parameter Graph
		Graph attributes, see Graphviz manuals. The default 'rankdir=LR' tells
		graph edges to go from left to right.

.Parameter Parameters
		See: help Invoke-Build -Parameter Parameters. Parameters may be needed
		only if a build file creates different task sets depending on them.

.Parameter NoShow
		Tells only to not show the graph after creation.
#>

param
(
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][string]$Output = "$env:TEMP\Graphviz.pdf",
	[string]$Graph = 'rankdir=LR',
	[hashtable]$Parameters,
	[switch]$NoShow
)

try { # To amend errors

# get dot.exe
$dot = if ($env:Graphviz) {"$env:Graphviz\dot.exe"} else {@(Get-Command dot.exe -ErrorAction Stop)[0].Path}
if (!(Test-Path -LiteralPath $dot)) {throw "Cannot find 'dot.exe'. See the script requirements."}

# output type
$type = [System.IO.Path]::GetExtension($Output)
if (!$type) {throw "Output file should have extension."}
$type = $type.Substring(1).ToLower()

# get tasks
Invoke-Build ? -File:$File -Parameters:$Parameters -Result:BuildList

# DOT code
$code = .{
	'digraph Tasks {'
	"graph [$Graph];"
	foreach($it in $BuildList.Values) {
		$name = $it.Name
		'"{0}";' -f $name
		foreach($job in $it.Jobs) {
			if ($job -is [string]) {
				'"{0}" -> "{1}";' -f $name, $job
			}
		}
	}
	'}'
}

#! temp file UTF8 no BOM
$temp = "$env:TEMP\Graphviz.dot"
[System.IO.File]::WriteAllLines($temp, $code)

# make
& $dot "-T$type" -o $Output $temp
if ($LastExitCode) {return}

# show
if (!$NoShow) {
	Invoke-Item $Output
}

} catch {
	if ($_.InvocationInfo.ScriptName -ne $MyInvocation.MyCommand.Path) {throw}
	$PSCmdlet.ThrowTerminatingError($_)
}
