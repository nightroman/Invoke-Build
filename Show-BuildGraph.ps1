
<#
.Synopsis
	Shows Invoke-Build task graph using Graphviz.
	Invoke-Build - Build Automation in PowerShell
	Copyright (c) 2011-2014 Roman Kuzmin

.Description
	Requires:
	- Graphviz: http://graphviz.org/
	- Graphviz\bin in the environment variable Graphviz or in the path.

	The script calls Invoke-Build.ps1 in order to get the tasks (WhatIf mode),
	builds the DOT file and calls Graphviz's dot.exe in order to visualize it
	using one of the supported output formats and the associated application.

	Tasks with code are shown as boxes, tasks without code are shown as ovals.
	Safe references are shown with dotted edges, regular calls are shown with
	solid edges. Call numbers on edges are not shown by default.

	EXAMPLES

	# Make and show temporary PDF for the default build script
	Show-BuildGraph

	# Make Build.png with call numbers and calls from top to bottom
	Show-BuildGraph -Number -Code '' -Output Build.png

.Parameter File
		See: help Invoke-Build -Parameter File
.Parameter Output
		The output file path and format specified by extension. For available
		formats simply use unlikely supported one and check the error message.
		The default is "$env:TEMP\Graphviz.pdf".
.Parameter Code
		Custom DOT code added to the graph definition, see Graphviz manuals.
		The default 'graph [rankdir=LR]' tells edges to go from left to right.
.Parameter Parameters
		See: help Invoke-Build -Parameter Parameters. Parameters are needed in
		special cases when they alter build task sets or task dependencies.
.Parameter NoShow
		Tells to not show the graph after creation.
.Parameter Number
		Tells to show task job numbers. Jobs are tasks (numbers are shown on
		edges) and own scripts (numbers are shown in task boxes after names).

.Inputs
	None
.Outputs
	None

.Link
	https://github.com/nightroman/Invoke-Build
#>

param(
	[Parameter(Position=1)][string]$File,
	[Parameter(Position=2)][string]$Output = "$env:TEMP\Graphviz.pdf",
	[string]$Code = 'graph [rankdir=LR]',
	[hashtable]$Parameters,
	[switch]$NoShow,
	[switch]$Number
)

try { # To amend errors

# resolve dot.exe
$dot = if ($env:Graphviz) {"$env:Graphviz\dot.exe"} else {@(Get-Command dot.exe -ErrorAction Stop)[0].Path}
if (!(Test-Path -LiteralPath $dot)) {throw "Cannot find 'dot.exe'."}

# output type
$type = [System.IO.Path]::GetExtension($Output)
if (!$type) {throw "Output file name should have an extension."}
$type = $type.Substring(1).ToLower()

# get tasks
$ib = Join-Path (Split-Path $MyInvocation.MyCommand.Path) Invoke-Build.ps1
$all = & $ib ?? -File:$File -Parameters:$Parameters

# DOT code
$text = @(
	'digraph Tasks {'
	$Code
	foreach($it in $all.Values) {
		$name = $it.Name
		'"{0}"' -f $name
		$num = 0
		$script = ''
		foreach($job in $it.Jobs) {
			++$num
			if ($job -is [string]) {
				$edge = ' '
				if ($Number) {
					$edge += "label=$num "
				}
				if ($it.Safe -contains $job) {
					$edge += "style=dotted "
				}
				'"{0}" -> "{1}" [{2}]' -f $name, $job, $edge
			}
			else {
				$script += "{$num}"
			}
		}
		if ($script) {
			if ($Number) {
				'"{0}" [ shape=box label="{0} {1}" ]' -f $name, $script
			}
			else {
				'"{0}" [ shape=box ]' -f $name
			}
		}
	}
	'}'
)

#! temp file UTF8 no BOM
$temp = "$env:TEMP\Graphviz.dot"
[System.IO.File]::WriteAllLines($temp, $text)

# make
& $dot "-T$type" -o $Output $temp
if ($LastExitCode) {return}

# show
if ($NoShow) {return}
Invoke-Item $Output

} catch {
	if ($_.InvocationInfo.ScriptName -ne $MyInvocation.MyCommand.Path) {throw}
	$PSCmdlet.ThrowTerminatingError($_)
}
